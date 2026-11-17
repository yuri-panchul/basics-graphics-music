`include "config.svh"
`include "lab_specific_board_config.svh"

// Digilent Cmod A7-35T, rev. B. Keep all ports named as in Digilent's XDC.
// See assembly_en.md / assembly_ru.md for connector numbering and supply levels.
module board_specific_top
# (
    parameter w_gpio        = 8,
    `ifdef CMOD_A7_NO_PLL
              screen_width  = 305,
    `else
              screen_width  = 640,
    `endif
              screen_height = 480,
              w_red         = 2,
              w_green       = 2,
              w_blue        = 2,
              w_x           = $clog2 (screen_width),
              w_y           = $clog2 (screen_height)
)
(
    input        sysclk,
    input  [1:0] btn,
    output [1:0] led,
    output       led0_r,
    output       led0_g,
    output       led0_b,
    output [7:0] ja,
    input        uart_txd_in,
    output       uart_rxd_out,

    inout        pio1, pio2, pio3, pio4, pio5, pio6, pio7, pio8,

    inout        pio26,  // TM1638 DIO, direct; module VCC and pull-ups at 3.3 V
    output       pio27,  // TM1638 CLK, direct 3.3 V logic
    output       pio28,  // TM1638 STB, direct 3.3 V logic
    output       pio29,  // INMP441 SCK
    output       pio30,  // INMP441 WS
    input        pio31,  // INMP441 SD; L/R is wired to GND
    output       pio32,  // DAC BCK
    output       pio33,  // DAC DIN
    output       pio34   // DAC LRCK / WS; DAC SCK / MCLK is wired to GND
);

    wire clk, locked;

    `ifdef CMOD_A7_NO_PLL
    // One 12 MHz clock domain, with no PLL/MMCM or fabric-generated clock.
    // 305 + 8 + 46 + 23 = 382 clocks/line; 525 lines => 59.83545 Hz.
    localparam clk_mhz = 12, pixel_mhz = 12;
    localparam h_front = 8, h_sync = 46, h_back = 23;
    assign locked = 1'b1;
    BUFG i_clock_buf (.I (sysclk), .O (clk));
    `else
    // Full-width VGA uses the Artix-7 MMCM:
    // 12 / 1 * 50 = 600 MHz VCO; 600 / 6 = 100 MHz system clock.
    // The common vga then advances one pixel every four cycles (25 MHz).
    localparam clk_mhz = 100, pixel_mhz = 25;
    localparam h_front = 16, h_sync = 96, h_back = 48;
    wire clk_unbuffered, feedback, feedback_buffered;

    MMCME2_BASE
    # (
        .CLKIN1_PERIOD    (83.333),
        .DIVCLK_DIVIDE    (1),
        .CLKFBOUT_MULT_F  (50.0),
        .CLKOUT0_DIVIDE_F (6.0),
        .STARTUP_WAIT     ("FALSE")
    )
    i_mmcm
    (
        .CLKIN1   (sysclk),
        .CLKFBIN  (feedback_buffered),
        .CLKFBOUT (feedback),
        .CLKOUT0  (clk_unbuffered),
        .LOCKED   (locked),
        .RST      (btn [0]),
        .PWRDWN   (1'b0)
    );

    BUFG i_feedback_buf (.I (feedback),       .O (feedback_buffered));
    BUFG i_clock_buf    (.I (clk_unbuffered), .O (clk));
    `endif

    // BTN0 asserts reset asynchronously; three clk edges release it.
    // In MMCM mode, loss of lock also asserts reset.
    wire reset_request = btn [0] | ~locked;
    (* ASYNC_REG = "TRUE" *) logic [2:0] reset_pipe = '1;

    always_ff @ (posedge clk or posedge reset_request)
        if (reset_request)
            reset_pipe <= '1;
        else
            reset_pipe <= { reset_pipe [1:0], 1'b0 };

    wire rst = reset_pipe [2];
    (* ASYNC_REG = "TRUE" *) logic [1:0] button_pipe;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            button_pipe <= '0;
        else
            button_pipe <= { button_pipe [0], btn [1] };

    // The RGB LED is active-low: red = reset/unlocked, green = running.
    assign led0_r = ~rst;
    assign led0_g =  rst;
    assign led0_b = 1'b1;

    // TM1638 has eight keys/LEDs/digits. Match the common concatenation options.
    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR
        localparam w_key = 9, w_led = 10;
    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638
        localparam w_key = 9, w_led = 10;
    `else
        localparam w_key = 8, w_led = 8;
    `endif
    localparam w_sw = 8, w_digit = 8;
    wire [7:0] tm_key, tm_led, digit, abcdefgh;
    wire [w_key - 1:0] key;
    wire [w_led - 1:0] lab_led;

    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR
        assign key = { tm_key, button_pipe [1] };
        assign { tm_led, led } = lab_led;
    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638
        assign key = { button_pipe [1], tm_key };
        assign { led, tm_led } = lab_led;
    `else
        assign key = tm_key | { 7'b0, button_pipe [1] };
        assign tm_led = lab_led;
        assign led = lab_led [1:0];
    `endif

    // There are no physical slide switches. S1..S8 provide momentary sw[0..7].
    wire [w_sw - 1:0] sw = tm_key;
    wire [w_x - 1:0] x;
    wire [w_y - 1:0] y;
    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;
    wire [23:0] mic;
    wire [15:0] sound;
    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.clk (clk), .rst (rst), .slow_clk (slow_clk));

    lab_top
    # (
        .clk_mhz (clk_mhz), .w_key (w_key), .w_sw (w_sw),
        .w_led (w_led), .w_digit (w_digit), .w_gpio (w_gpio),
        .screen_width (screen_width), .screen_height (screen_height),
        .w_red (w_red), .w_green (w_green), .w_blue (w_blue)
    )
    i_lab_top
    (
        .clk (clk), .rst (rst), .slow_clk (slow_clk),
        .key (key), .sw (sw), .led (lab_led),
        .abcdefgh (abcdefgh), .digit (digit),
        .x (x), .y (y), .red (red), .green (green), .blue (blue),
        .mic (mic), .sound (sound),
        .uart_rx (uart_txd_in), .uart_tx (uart_rxd_out),
        .gpio ({ pio8, pio7, pio6, pio5, pio4, pio3, pio2, pio1 })
    );

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        wire hs, vs, display_on;
        // Include blanking in the timing-counter widths (525 lines need 10 bits).
        localparam w_video_x = $clog2 (screen_width + h_front + h_sync + h_back),
                   w_video_y = $clog2 (screen_height + 45);
        wire [w_video_x - 1:0] video_x;
        wire [w_video_y - 1:0] video_y;
        assign x = w_x' (video_x);
        assign y = w_y' (video_y);

        vga
        # (
            .HPOS_WIDTH (w_video_x), .VPOS_WIDTH (w_video_y),
            .H_DISPLAY (screen_width), .V_DISPLAY (screen_height),
            .H_FRONT (h_front), .H_SYNC (h_sync), .H_BACK (h_back),
            .CLK_MHZ (clk_mhz), .PIXEL_MHZ (pixel_mhz)
        )
        i_vga
        (
            .clk (clk), .rst (rst), .hsync (hs), .vsync (vs),
            .display_on (display_on), .hpos (video_x), .vpos (video_y),
            .pixel_clk ()
        );

        // Tiny VGA: physical JA 1/2/3/4 = R1/G1/B1/VS;
        //                    JA 7/8/9/10 = R0/G0/B0/HS.
        // Default two-bit channels also allow a wider lab channel's top bits.
        wire [1:0] r2 = display_on && !rst ? red   [w_red   - 1 -: 2] : 2'b0;
        wire [1:0] g2 = display_on && !rst ? green [w_green - 1 -: 2] : 2'b0;
        wire [1:0] b2 = display_on && !rst ? blue  [w_blue  - 1 -: 2] : 2'b0;
        assign ja = { hs, b2 [0], g2 [0], r2 [0], vs, b2 [1], g2 [1], r2 [1] };
    `else
        assign x = '0;
        assign y = '0;
        assign ja = 8'b10001000;  // Inactive high sync, black RGB.
    `endif

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
        wire [7:0] hgfedcba;
        for (genvar i = 0; i < 8; i++)
        begin : segment_order
            assign hgfedcba [i] = abcdefgh [7 - i];
        end

        `ifdef USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
            wire [15:0] tm_keys_all;
            assign tm_key = tm_keys_all [7:0];
        `else
            wire [7:0] tm_keys_all;
            assign tm_key = tm_keys_all;
        `endif

        `ifdef SPLIT_TM1638_DIO_INOUT_SIGNAL
            wire tm_data_out, tm_data_enable;
            assign pio26 = tm_data_enable ? tm_data_out : 1'bz;
        `endif

        tm1638_board_controller # (.clk_mhz (clk_mhz), .w_digit (w_digit))
        i_tm1638
        (
            .clk (clk), .rst (rst), .hgfedcba (hgfedcba), .digit (digit),
            .ledr (tm_led), .keys (tm_keys_all), .sio_clk (pio27), .sio_stb (pio28),
            `ifdef SPLIT_TM1638_DIO_INOUT_SIGNAL
                .sio_data_in (pio26), .sio_data_out (tm_data_out),
                .sio_data_out_en (tm_data_enable)
            `else
                .sio_data (pio26)
            `endif
        );
    `else
        assign tm_key = '0;
        assign pio26 = 1'bz;
        assign pio27 = 1'b1;
        assign pio28 = 1'b1;
    `endif

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
        inmp441_mic_i2s_receiver # (.clk_mhz (clk_mhz))
        i_microphone
        (
            .clk (clk), .rst (rst), .lr (), .ws (pio30),
            .sck (pio29), .sd (pio31), .value (mic)
        );
    `else
        assign mic = '0;
        assign pio29 = 1'b0;
        assign pio30 = 1'b0;
    `endif

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
        // PCM5100A/PCM5102A use their BCK PLL: no external MCLK is needed.
        i2s_audio_out # (.clk_mhz (clk_mhz))
        i_audio_out
        (
            .clk (clk), .reset (rst), .data_in (sound),
            .mclk (), .bclk (pio32), .sdata (pio33), .lrclk (pio34)
        );
    `else
        assign pio32 = 1'b0;
        assign pio33 = 1'b0;
        assign pio34 = 1'b0;
    `endif

endmodule
