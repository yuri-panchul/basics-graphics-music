`timescale 1 ns / 1 ps

module tb;
    logic CLOCK1_50 = 0;
    logic [1:0] KEY = '1;
    logic [3:0] SW = '0;
    wire [7:0] LEDR;
    tri [35:0] GPIO_0, GPIO_1;
    logic gpio_input = 0;
    // Drives only the test double for the Intel Reset Release IP.
    logic ninit_done_request = 1;
    wire HDMI_TX_CLK, HDMI_TX_DE, HDMI_TX_HS, HDMI_TX_VS;
    wire [23:0] HDMI_TX_D;
    wire HDMI_I2S0, HDMI_LRCLK, HDMI_MCLK, HDMI_SCLK;
    wire I2C_SCL;
    tri1 I2C_SDA;
    logic hdmi_ack_low = 0;
    assign I2C_SDA = hdmi_ack_low ? 1'b0 : 1'bz;

    // Opposite levels distinguish the two physical GPIO headers.
    assign GPIO_0 [0] = ~ gpio_input;
    assign GPIO_1 [0] =   gpio_input;

    // The 1 MHz test parameter shortens the real lab counter simulation.
    // The input clock period is immaterial to these synchronous assertions.
    `ifdef DE25_TEST_VIDEO
        localparam test_clk_mhz = 50;
    `else
        localparam test_clk_mhz = 1;
    `endif

    board_specific_top # (.clk_mhz (test_clk_mhz)) dut
    (
        .CLOCK1_50 ( CLOCK1_50 ),
        .KEY       ( KEY       ),
        .SW        ( SW        ),
        .LEDR      ( LEDR      ),
        .GPIO_0    ( GPIO_0    ),
        .GPIO_1    ( GPIO_1    ),
        .HDMI_TX_CLK ( HDMI_TX_CLK ),
        .HDMI_TX_DE  ( HDMI_TX_DE  ),
        .HDMI_TX_D   ( HDMI_TX_D   ),
        .HDMI_TX_HS  ( HDMI_TX_HS  ),
        .HDMI_TX_VS  ( HDMI_TX_VS  ),
        .HDMI_I2S0   ( HDMI_I2S0   ),
        .HDMI_LRCLK  ( HDMI_LRCLK  ),
        .HDMI_MCLK   ( HDMI_MCLK   ),
        .HDMI_SCLK   ( HDMI_SCLK   ),
        .I2C_SCL     ( I2C_SCL     ),
        .I2C_SDA     ( I2C_SDA     ),
        .HDMI_TX_INT ( 1'b1 )
    );

    always #5 CLOCK1_50 = ~ CLOCK1_50;

    logic expected_mux;
    logic [3:0] expected_decode;
    logic [7:0] expected_led;
    integer pixel_high_cycles = 0;
    integer display_cycles = 0;
    integer hsync_low_cycles = 0;
    integer visible_pixel_count = 0;
    logic count_frame_pixels = 0;
    time frame_start;
    logic [23:0] hdmi_transaction;
    integer hdmi_successful_writes = 0;

    always @(posedge HDMI_TX_CLK)
        if (count_frame_pixels && HDMI_TX_DE)
            visible_pixel_count ++;

    `ifdef DE25_TEST_GRAPHICS_I2C
        task receive_hdmi_write (input logic acknowledge, output logic [23:0] transaction);
            // Observe standard START/STOP and MSB-first bytes on the physical
            // bus, then drive the receiver's open-drain acknowledgement.
            do @(negedge I2C_SDA); while (I2C_SCL !== 1'b1);
            for (int byte_index = 2; byte_index >= 0; byte_index --)
            begin
                for (int bit_index = 7; bit_index >= 0; bit_index --)
                begin
                    @(posedge I2C_SCL);
                    transaction [byte_index * 8 + bit_index] = I2C_SDA;
                end
                @(negedge I2C_SCL);
                hdmi_ack_low = acknowledge;
                @(posedge I2C_SCL);
                @(negedge I2C_SCL);
                #1;
                hdmi_ack_low = 0;
            end
            do @(posedge I2C_SDA); while (I2C_SCL !== 1'b1);
        endtask
    `endif

    initial
    begin
        #1;
        SW [3] = 1'b1;
        #2;
        SW [3] = 1'b0;
        repeat (2) @(posedge CLOCK1_50);
        #1;

        `ifdef DE25_TEST_MUX
            for (int pattern = 0; pattern < 8; pattern ++)
            begin
                SW [2:0] = 3' (pattern);
                // Keys must not select the mux branch on a two-key board.
                for (int buttons = 0; buttons < 4; buttons ++)
                begin
                    KEY = 2' (buttons);
                    #1;
                    expected_mux = SW [2] ? SW [1] : SW [0];
                    // mux4 is the deliberate unsolved exercise (constant 0).
                    expected_led = expected_mux ? 8'hef : 8'h00;
                    if (LEDR !== ~ expected_led)
                        $fatal (1, "Mux/key/switch/LED mapping: SW=%b KEY=%b LEDR=%h",
                                SW, KEY, LEDR);
                end
            end
            $display ("PASS: MUX");
        `endif

        `ifdef DE25_TEST_DECODER
            for (int buttons = 0; buttons < 4; buttons ++)
            begin
                KEY = 2' (buttons);
                #1;
                expected_decode = 4'b0001 << (~ KEY);
                expected_led = { expected_decode, expected_decode };
                if (LEDR !== ~ expected_led)
                    $fatal (1, "Active-low key/LED decoding: KEY=%b LEDR=%h", KEY, LEDR);
            end
            $display ("PASS: DECODER");
        `endif

        `ifdef DE25_TEST_COUNTER
            if (LEDR !== 8'hff)
                $fatal (1, "Reset did not clear counter outputs");
            // At clk_mhz=1, the upper eight bits of the 20-bit counter
            // first change on the 4096th clock edge.
            repeat (4095) @(posedge CLOCK1_50);
            #1;
            if (LEDR !== 8'hff)
                $fatal (1, "Counter advanced too early: %h", LEDR);
            @(posedge CLOCK1_50);
            #1;
            if (LEDR !== 8'hfe)
                $fatal (1, "Clock/counter/LED mapping failed: %h", LEDR);
            @(negedge CLOCK1_50);
            #1;
            SW [3] = 1'b1;
            #1;
            if (LEDR !== 8'hff)
                $fatal (1, "SW[3] must reset asynchronously");
            SW [3] = 1'b0;
            repeat (2) @(posedge CLOCK1_50);
            #1;
            repeat (4096) @(posedge CLOCK1_50);
            #1;
            if (LEDR !== 8'hfe)
                $fatal (1, "Counter did not restart after reset release");
            $display ("PASS: COUNTER");
        `endif

        `ifdef DE25_TEST_PROBE
            for (int switches = 0; switches < 16; switches ++)
            begin
                SW = 4' (switches);
                for (int buttons = 0; buttons < 4; buttons ++)
                begin
                    KEY = 2' (buttons);
                    gpio_input = 1' (switches ^ buttons);
                    repeat (2) @(posedge CLOCK1_50);
                    #1;
                    expected_led = { SW [3], SW [2:0], ~ KEY, 1'b0, gpio_input };
                    if (LEDR !== ~ expected_led)
                        $fatal (1, "Lab input or GPIO_1 mapping failed: %h", LEDR);
                    if (GPIO_1 [1] !== ~ KEY [0] || GPIO_0 [1] !== 1'bz)
                        $fatal (1, "Lab GPIO output is routed to the wrong header");
                end
            end
            $display ("PASS: PROBE");
        `endif

        `ifdef DE25_TEST_GRAPHICS
            // A 640x480 line has 800 pixel periods: 640 visible pixels,
            // a 96-pixel active-low sync pulse and 64 porch pixels.
            // Start measurements after a line to avoid reset transients.
            repeat (1600) @(posedge CLOCK1_50);
            for (int cycle = 0; cycle < 1600; cycle ++)
            begin
                @(posedge CLOCK1_50);
                #1;
                if ((^ { HDMI_TX_CLK, HDMI_TX_DE, HDMI_TX_HS, HDMI_TX_VS }) === 1'bx)
                    $fatal (1, "Undefined HDMI timing outputs: clk=%b de=%b hs=%b vs=%b",
                            HDMI_TX_CLK, HDMI_TX_DE, HDMI_TX_HS, HDMI_TX_VS);
                if (HDMI_TX_D !== 24'h123456)
                    $fatal (1, "Incorrect RGB channel order: %h", HDMI_TX_D);
                if (HDMI_TX_VS !== 1'b1)
                    $fatal (1, "Unexpected vertical sync during a visible line");
                if ({ HDMI_I2S0, HDMI_LRCLK, HDMI_MCLK, HDMI_SCLK } !== 4'b0)
                    $fatal (1, "Disabled HDMI audio must be held inactive");
                pixel_high_cycles += HDMI_TX_CLK;
                display_cycles += HDMI_TX_DE;
                hsync_low_cycles += !HDMI_TX_HS;
            end
            if (pixel_high_cycles != 800 || display_cycles != 1280 || hsync_low_cycles != 192)
                $fatal (1, "Incorrect line timing: pixel=%0d display=%0d hsync=%0d",
                        pixel_high_cycles, display_cycles, hsync_low_cycles);
            $display ("PASS: GRAPHICS");
        `endif

        `ifdef DE25_TEST_GRAPHICS_FRAME
            // The vertical counter must include all 45 blanking lines.
            // A counter sized only for y=0..479 wraps at511, which a line
            // test misses even though VS pulses still occur at490..491.
            @(negedge HDMI_TX_VS);
            frame_start = $time;
            count_frame_pixels = 1;
            @(posedge HDMI_TX_VS);
            if ($time - frame_start != 2 * 800 * 2 * 10)
                $fatal (1, "Vertical sync must span exactly two whole lines");
            @(negedge HDMI_TX_VS);
            count_frame_pixels = 0;
            if ($time - frame_start != 525 * 800 * 2 * 10)
                $fatal (1, "Incorrect frame period: %0t, expected 525 lines", $time - frame_start);
            if (visible_pixel_count != 640 * 480)
                $fatal (1, "Incorrect frame display area: %0d pixels", visible_pixel_count);
            $display ("PASS: GRAPHICS_FRAME");
        `endif

        `ifdef DE25_TEST_GRAPHICS_I2C
            // Exercise a switch reset after startup. This provides a real
            // reset edge to the divided-clock I2C domain in event simulation.
            SW [3] = 1;
            #2;
            SW [3] = 0;
            repeat (2) @(posedge CLOCK1_50);
            #1;
            // Terasic's ADV7513 initialization begins with address 0x72,
            // register 0x98=0x03, then register 0x01=0x00. A rejected write
            // must be retried before the configuration moves on.
            receive_hdmi_write (0, hdmi_transaction);
            if (hdmi_transaction !== 24'h729803)
                $fatal (1, "Incorrect first ADV7513 write: %h", hdmi_transaction);
            receive_hdmi_write (1, hdmi_transaction);
            if (hdmi_transaction !== 24'h729803)
                $fatal (1, "ADV7513 write was not retried after NACK: %h", hdmi_transaction);
            hdmi_successful_writes ++;
            receive_hdmi_write (1, hdmi_transaction);
            if (hdmi_transaction !== 24'h720100)
                $fatal (1, "ADV7513 configuration did not advance after ACK: %h", hdmi_transaction);
            hdmi_successful_writes ++;
            for (int register_index = 2; register_index < 33; register_index ++)
            begin
                receive_hdmi_write (1, hdmi_transaction);
                if (hdmi_transaction [23:16] !== 8'h72)
                    $fatal (1, "ADV7513 writes must address slave 0x39 in write mode");
                hdmi_successful_writes ++;
                if (register_index < 32 && dut.i_i2c_hdmi_conf.READY !== 1'b0)
                    $fatal (1, "ADV7513 configuration reported READY too early");
            end
            if (hdmi_successful_writes != 33 || hdmi_transaction !== 24'h72fa7d)
                $fatal (1, "Incomplete ADV7513 initialization: writes=%0d final=%h",
                        hdmi_successful_writes, hdmi_transaction);
            wait (dut.i_i2c_hdmi_conf.READY === 1'b1);
            $display ("PASS: GRAPHICS_I2C");
        `endif

        `ifdef DE25_TEST_RESET_CONTRACT
            // The probe exposes the lab's reset on LEDR[7], inverted.
            // This validates the wrapper handshake, not the vendor IP model.
            repeat (3) @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "ninit_done must hold the lab in reset at startup");

            @(negedge CLOCK1_50);
            ninit_done_request = 0;
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "Reset must not release between clock edges");
            @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "Reset released before the second clock edge");
            @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b1)
                $fatal (1, "Reset failed to release on the second clock edge");

            @(negedge CLOCK1_50);
            #1;
            ninit_done_request = 1;
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "A new ninit_done request must assert reset asynchronously");
            ninit_done_request = 0;
            @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "Repeated startup reset released too early");
            @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b1)
                $fatal (1, "Repeated startup reset did not release");

            @(negedge CLOCK1_50);
            #1;
            SW [3] = 1;
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "SW[3] must still assert reset after FPGA initialization");
            SW [3] = 0;
            @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b0)
                $fatal (1, "Switch reset released too early");
            @(posedge CLOCK1_50);
            #1;
            if (LEDR [7] !== 1'b1)
                $fatal (1, "Switch reset did not release on the second clock edge");
            $display ("PASS: RESET_CONTRACT");
        `endif
        $finish;
    end

    initial
    begin
        `ifdef DE25_TEST_GRAPHICS_I2C
        #100000000;
        `elsif DE25_TEST_VIDEO
        #20000000;
        `else
        #100000;
        `endif
        $fatal (1, "Simulation timed out");
    end
endmodule
