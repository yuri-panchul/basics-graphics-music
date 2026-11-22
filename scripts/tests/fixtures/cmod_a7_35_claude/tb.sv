// A self-checking testbench of the Cmod A7 configurations of Claude, with
// lab_top.sv of this directory as the lab. test_cmod_a7_35_claude.py
// compiles it with one configuration's board_specific_top.sv and defines:
//
//   CMOD_TEST_SCREEN_WIDTH  640 (the MMCM at 50 MHz), 304 or 320 (no MMCM)
//   CMOD_TEST_NO_TM1638     for the configurations without TM1638
//
// It checks the pins of the board: the clock and reset, the VGA timing
// measured in nanoseconds on the TinyVGA pins, the colors, an INMP441
// microphone and an I2S DAC played from the other end of their wires, the
// buttons, the LEDs and the RGB LED, the GPIO pins, the UART and the
// TM1638 pins. It prints PASS at the end or stops with $fatal.

`timescale 1 ns / 1 ps

`ifndef CMOD_TEST_SCREEN_WIDTH
    `define CMOD_TEST_SCREEN_WIDTH 640
`endif

module tb;

    localparam screen_width     = `CMOD_TEST_SCREEN_WIDTH,
               no_pll           = screen_width != 640,

               h_front          = screen_width == 640 ? 16 : 8,
               h_sync           = screen_width == 640 ? 96 : screen_width == 320 ? 48 : 46,
               h_back           = screen_width == 640 ? 48 : screen_width == 320 ? 24 : 23,
               h_total          = screen_width + h_front + h_sync + h_back,
               v_total          = 525,

               clocks_per_pixel = no_pll ? 1 : 2,      // 12 MHz or 50 / 25 MHz
               clocks_per_mic   = 1024,                // One microphone sample
               clocks_per_dac   = no_pll ? 256 : 1024; // One DAC sample (LRCK)

    localparam real sysclk_period = 1000.0 / 12,
                    clk_period    = no_pll ? sysclk_period : 20.0,
                    line_period   = h_total * clocks_per_pixel * clk_period;

    `ifdef CMOD_TEST_NO_TM1638
        localparam with_tm1638 = 0;
    `else
        localparam with_tm1638 = 1;
    `endif

    //------------------------------------------------------------------------

    logic       sysclk = 1'b0;
    logic [1:0] btn    = 2'b00;
    wire  [1:0] led;
    wire        led0_r, led0_g, led0_b;
    wire  [7:0] ja;
    logic       uart_txd_in = 1'b1;
    wire        uart_rxd_out;

    wire        pio1,  pio2,  pio3,  pio4,  pio5,  pio6,  pio7,         // GPIO
                pio8,  pio9,  pio10, pio11, pio12, pio13, pio14,
                pio17, pio18, pio19, pio20,
                pio33, pio34, pio35, pio36, pio37, pio38, pio39, pio40,
                pio41, pio42, pio43, pio44, pio45, pio46, pio47, pio48;
    wire        pio21, pio22, pio23;   // DAC BCK, DIN, LCK
    wire        pio26, pio27;          // TM1638 STB, CLK
    tri1        pio28;                 // TM1638 DIO, pulled up on the module
    wire        pio29, pio30, pio31;   // INMP441 SCK, WS, L/R
    logic       pio32 = 1'b0;          // INMP441 SD

    always # (sysclk_period / 2) sysclk = ~ sysclk;

    // The GPIO pattern that lab_top.sv of this directory drives

    localparam [63:0] gpio_pattern = 64'h9c5a_3e71_d2b6_48a6;

    board_specific_top dut (.*);

    //------------------------------------------------------------------------
    // Helpers

    task automatic fail (input string what);
        $fatal (1, "FAIL: %s", what);
    endtask

    function automatic bit near (input real actual, input real expected);
        return actual > expected * 0.999 && actual < expected * 1.001;
    endfunction

    initial
    begin
        # 60_000_000;
        fail ("timeout");
    end

    //------------------------------------------------------------------------
    // INMP441: after a change of WS it sends one empty bit, then 24 bits of
    // a sample, MSB first, on the falling edges of SCK, in the half of the
    // WS period that its L/R pin selects.

    localparam [23:0] mic_sample = 24'hc3a51e;

    logic mic_ws_seen = 1'b0;
    int   mic_bit     = 0;

    // It reads WS 1 ns after the falling edge of SCK: both change on the
    // same clock edge of the FPGA.

    always @ (negedge pio29)
    begin
        # 1;

        if (pio30 != mic_ws_seen)
        begin
            mic_ws_seen = pio30;
            mic_bit     = 0;
        end
        else
        begin
            mic_bit ++;
        end

        pio32 <= pio30 == pio31 && mic_bit >= 1 && mic_bit <= 24 ?
                     mic_sample [24 - mic_bit] : 1'b0;
    end

    //------------------------------------------------------------------------
    // I2S DAC: it reads DIN on the rising edges of BCK. The MSB of a
    // sample comes on the second rising edge after LCK changes. A reset
    // restarts the word in the FPGA, maybe without a change of LCK, so the
    // DAC checks only the words that start after a change of LCK.

    logic        dac_synced   = 1'b0;
    logic        dac_lck_seen = 1'b0;
    int          dac_bit      = 0;
    logic [15:0] dac_word;
    int          dac_words_ok = 0;

    always @ (posedge dut.rst)
        dac_synced = 1'b0;

    always @ (posedge pio21)
    begin
        if (dut.rst)
            dac_synced = 1'b0;

        if (pio23 != dac_lck_seen)
        begin
            dac_lck_seen = pio23;
            dac_bit      = 0;
            dac_synced   = ! dut.rst;
        end
        else
        begin
            dac_bit ++;
        end

        if (dac_bit >= 1 && dac_bit <= 16)
            dac_word = { dac_word [14:0], pio22 };

        if (dac_bit == 16 && dac_synced)
        begin
            if (dac_word !== 16'h5a3c)
                fail ($sformatf ("DAC sample %h, expected 5a3c", dac_word));

            dac_words_ok ++;
        end
    end

    //------------------------------------------------------------------------
    // Periods measured on the pins

    realtime last_hs, last_vs, last_mic_ws, last_dac_lck;
    int      n_lines = 0, n_frames = 0, n_mic = 0, n_dac = 0;

    always @ (negedge ja [7])
        if (! dut.rst)
        begin
            if (last_hs > 0 && ! near ($realtime - last_hs, line_period))
                fail ($sformatf ("VGA line %0.1f ns, expected %0.1f ns",
                                 $realtime - last_hs, line_period));

            last_hs = $realtime;
            n_lines ++;
        end

    always @ (negedge ja [3])
        if (! dut.rst)
        begin
            if (last_vs > 0 && ! near ($realtime - last_vs, line_period * v_total))
                fail ($sformatf ("VGA frame %0.1f ns", $realtime - last_vs));

            last_vs = $realtime;
            n_frames ++;
        end

    always @ (posedge pio30)
        if (! dut.rst)
        begin
            if (last_mic_ws > 0 && ! near ($realtime - last_mic_ws, clocks_per_mic * clk_period))
                fail ($sformatf ("INMP441 WS period %0.1f ns", $realtime - last_mic_ws));

            last_mic_ws = $realtime;
            n_mic ++;
        end

    always @ (posedge pio23)
        if (! dut.rst)
        begin
            if (last_dac_lck > 0 && ! near ($realtime - last_dac_lck, clocks_per_dac * clk_period))
                fail ($sformatf ("DAC LCK period %0.1f ns", $realtime - last_dac_lck));

            last_dac_lck = $realtime;
            n_dac ++;
        end

    //------------------------------------------------------------------------
    // The RGB LED: count how many of 4096 oscillator clocks each color is lit

    task automatic check_rgb (input bit in_reset);
        int n_red = 0, n_green = 0, n_blue = 0;

        repeat (4096)
        begin
            @ (negedge sysclk);
            n_red   += ! led0_r;
            n_green += ! led0_g;
            n_blue  += ! led0_b;
        end

        if (   n_red   != (in_reset ? 256 : 0)
            || n_green != (in_reset ? 0 : 256)
            || n_blue  != 0)
            fail ($sformatf ("RGB LED lit %0d, %0d, %0d of 4096 clocks %s",
                             n_red, n_green, n_blue, in_reset ? "in reset" : "running"));
    endtask

    //------------------------------------------------------------------------
    // One frame of VGA: the clocks of the active area, of the sync pulses
    // and the colors in and out of the active area. A window of exactly one
    // frame of clocks counts each part once wherever the window starts, but
    // the first frame after a reset is shorter, so the window starts with
    // the vertical sync pulse of the frame after it.

    task automatic check_frame;
        int n_active = 0, n_hsync = 0, n_vsync = 0;

        @ (negedge ja [3]);

        repeat (h_total * v_total * clocks_per_pixel)
        begin
            @ (negedge dut.clk);

            n_hsync += ! ja [7];
            n_vsync += ! ja [3];

            if (dut.i_vga.display_on)
            begin
                n_active ++;

                // red 10, green 01, blue 11: ja [0], [1], [2] are bit 1,
                // ja [4], [5], [6] are bit 0

                if ({ ja [6:4], ja [2:0] } !== 6'b110_101)
                    fail ($sformatf ("colors %b on the TinyVGA pins", ja));

                if (dut.x !== dut.i_vga.hpos || dut.y !== dut.i_vga.vpos)
                    fail ("lab coordinates");
            end
            else if ({ ja [6:4], ja [2:0] } !== '0)
            begin
                fail ("color outside the active area");
            end
        end

        if (n_active != screen_width * 480 * clocks_per_pixel)
            fail ($sformatf ("%0d active clocks, expected %0d x 480", n_active, screen_width));

        if (n_hsync != h_sync * v_total * clocks_per_pixel)
            fail ($sformatf ("%0d clocks of horizontal sync", n_hsync));

        if (n_vsync != 2 * h_total * clocks_per_pixel)
            fail ($sformatf ("%0d clocks of vertical sync, expected 2 lines", n_vsync));
    endtask

    //------------------------------------------------------------------------

    initial
    begin
        // Reset at power-up

        # 1;

        if (dut.rst !== 1'b1)
            fail ("no reset at power-up");

        if (! no_pll)
        begin
            repeat (32) @ (posedge sysclk);

            if (dut.locked !== 1'b0 || dut.rst !== 1'b1)
                fail ("reset released before the MMCM locked");

            wait (dut.locked === 1'b1);
        end

        // Count the rising edges of the clock from the end of the cause

        repeat (2) @ (posedge dut.clk);
        # 1;

        if (dut.rst !== 1'b1)
            fail ("reset released before the third clock edge");

        @ (posedge dut.clk);
        # 1;

        if (dut.rst !== 1'b0)
            fail ("reset not released on the third clock edge");

        begin
            realtime t;

            @ (posedge dut.clk) t = $realtime;
            @ (posedge dut.clk);

            if (! near ($realtime - t, clk_period))
                fail ($sformatf ("clock period %0.3f ns, expected %0.3f ns",
                                 $realtime - t, clk_period));
        end

        // Pins that do not depend on time

        // lab_top.sv drives a pattern on its GPIO; gpio [0] is DIP 1,
        // gpio [14] DIP 17 and gpio [18] DIP 33

        begin
            logic [33:0] gpio_pins;

            gpio_pins = { pio48, pio47, pio46, pio45, pio44, pio43, pio42, pio41,
                          pio40, pio39, pio38, pio37, pio36, pio35, pio34, pio33,
                          pio20, pio19, pio18, pio17,
                          pio14, pio13, pio12, pio11, pio10, pio9,  pio8,  pio7,
                          pio6,  pio5,  pio4,  pio3,  pio2,  pio1 };

            if (gpio_pins !== gpio_pattern [33:0])
                fail ($sformatf ("GPIO pins DIP 48 to 1 are %b, expected %b",
                                 gpio_pins, gpio_pattern [33:0]));
        end

        uart_txd_in = 1'b0;
        # 1;

        if (uart_rxd_out !== 1'b0)
            fail ("UART loopback");

        uart_txd_in = 1'b1;

        if (pio31 !== 1'b0)
            fail ("INMP441 L/R must select the left channel");

        if (! with_tm1638)
        begin
            if (pio26 !== 1'b1 || pio27 !== 1'b1)
                fail ("TM1638 STB and CLK must stay high without TM1638");

            if ($sformatf ("%v", pio28) != "Pu1")
                fail ($sformatf ("DIO must not be driven without TM1638, it is %v", pio28));
        end

        check_rgb (0);

        // Buttons. Without TM1638 they are the keys of the labs, read
        // as they are, and the lab shows the keys on the LEDs; they do
        // not reset the design. With TM1638 either button resets it.

        if (! with_tm1638)
        begin
            for (int b = 0; b < 4; b ++)
            begin
                @ (negedge dut.clk);
                btn = b;
                # 1;

                if (led !== btn || dut.i_lab_top.key !== btn || dut.i_lab_top.sw !== btn)
                    fail ($sformatf ("buttons %b: keys %b, LEDs %b", btn, dut.i_lab_top.key, led));

                repeat (8) @ (negedge dut.clk);

                if (dut.rst !== 1'b0)
                    fail ("a button reset the design without TM1638");
            end

            btn = 2'b00;
        end
        else
        begin
            for (int b = 1; b < 4; b ++)
            begin
                @ (negedge dut.clk);
                btn = b;
                # 1;

                if (dut.rst !== 1'b1)
                    fail ($sformatf ("buttons %b did not reset the design", btn));

                if (b == 3)
                    check_rgb (1);

                @ (negedge dut.clk);
                btn = 2'b00;
                repeat (2) @ (negedge dut.clk);

                if (dut.rst !== 1'b1)
                    fail ("button reset released too early");

                @ (negedge dut.clk);

                if (dut.rst !== 1'b0)
                    fail ("button reset not released");
            end
        end

        // The RGB LED in reset, where the buttons cannot reset the design:
        // the lock of the MMCM is lost, or the reset chain is set

        if (! with_tm1638)
        begin
            if (! no_pll)
                force dut.locked = 1'b0;
            else
                force dut.reset_chain = 3'b111;

            # 1;
            check_rgb (1);

            if (! no_pll)
                release dut.locked;
            else
                release dut.reset_chain;

            wait (dut.rst === 1'b0);
        end

        // TM1638 is scanned while the design runs

        if (with_tm1638)
        begin
            fork : tm1638_activity
                @ (negedge pio26);
                # 2_000_000 fail ("TM1638 STB never went low");
            join_any

            disable tm1638_activity;
        end

        // A whole frame of VGA, then the sound and the microphone

        last_hs = 0; last_vs = 0; last_mic_ws = 0; last_dac_lck = 0;
        n_lines = 0; n_frames = 0; n_mic = 0; n_dac = 0;

        check_frame;
        @ (negedge ja [3]);   // A second start of a frame on the VS pin

        if (n_lines < v_total || n_frames < 2 || n_mic < 4 || n_dac < 4)
            fail ($sformatf ("too few periods: %0d lines, %0d frames, %0d microphone, %0d DAC",
                             n_lines, n_frames, n_mic, n_dac));

        if (dac_words_ok < 4)
            fail ("no DAC samples");

        if (dut.mic !== mic_sample)
            fail ($sformatf ("microphone sample %h, expected %h", dut.mic, mic_sample));

        begin
            string clock_text = "50 MHz from the MMCM", tm1638_text = "with TM1638";

            if (no_pll)
                clock_text = "12 MHz, no MMCM";

            if (! with_tm1638)
                tm1638_text = "without TM1638";

            $display ("PASS: %0dx480, %s, %s; %0d lines, %0d DAC samples",
                      screen_width, clock_text, tm1638_text, n_lines, dac_words_ok);
        end

        $finish;
    end

endmodule
