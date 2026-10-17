`timescale 1 ns / 1 ps

module tb;
    logic CLOCK1_50 = 0;
    logic [1:0] KEY = '1;
    logic [3:0] SW = '0;
    wire [7:0] LEDR;
    tri [35:0] GPIO_0, GPIO_1;
    logic serial_rx = 1, mic_sd = 0;
    logic lab_uart_tx = 1, lab_gpio_out = 0, gpio_input = 0;
    logic [15:0] lab_sound = 16'ha53c;
    logic [7:0] lab_segments = 8'hd2, lab_digits = 8'h42;
    logic [7:0] tm_keys = 0;
    logic [7:0] expected_keys;
    logic [15:0] captured_audio;
    time edge_time;

    assign GPIO_0 [5] = mic_sd;
    assign GPIO_0 [6] = serial_rx;
    assign GPIO_1 [0] = gpio_input;

    board_specific_top dut
    (
        .CLOCK1_50 (CLOCK1_50), .KEY (KEY), .SW (SW), .LEDR (LEDR),
        .GPIO_0 (GPIO_0), .GPIO_1 (GPIO_1), .HDMI_TX_INT (1'b1)
    );

    always #10 CLOCK1_50 = ~CLOCK1_50;

    task check_unused_pins;
        // Unused signals include the pins that older wrappers drove as
        // makeshift GND/VCC. Accessories must use real supply pins instead.
        for (int pin = 0; pin < 36; pin ++)
        begin
            if (!(pin == 0 || pin == 2 || pin == 4 || pin == 5 || pin == 6 || pin == 7 ||
                  pin == 11 || pin == 13 || pin == 15 || pin == 17 ||
                  pin == 27 || pin == 29 || pin == 31))
                if (GPIO_0 [pin] !== 1'bz)
                    $fatal (1, "Accessory unexpectedly drives unused GPIO_0[%0d]", pin);
        end
        `ifndef DE25_NANO_USE_INMP441
            if ({GPIO_0 [0], GPIO_0 [2], GPIO_0 [4]} !== 3'bzzz)
                $fatal (1, "Disabled microphone drives GPIO outputs");
            if (dut.i_lab_top.mic !== 24'b0)
                $fatal (1, "Disabled microphone input is not zero");
        `endif
        `ifndef DE25_NANO_USE_I2S_AUDIO
            if ({GPIO_0 [17], GPIO_0 [15], GPIO_0 [11], GPIO_0 [13]} !== 4'bzzzz)
                $fatal (1, "Disabled audio drives GPIO outputs");
        `endif
        `ifndef DE25_NANO_USE_TM1638
            if ({GPIO_0 [27], GPIO_0 [29], GPIO_0 [31]} !== 3'bzzz)
                $fatal (1, "Disabled TM1638 drives GPIO outputs");
        `endif
    endtask

    `ifdef DE25_NANO_USE_INMP441
        task send_microphone_sample (input [23:0] sample);
            // Standard left-channel I2S: MSB first, one serial-clock delay
            // after WS falls. Stimulus uses physical pins, not internal counts.
            @(negedge GPIO_0 [2]);
            #1;
            for (int bit_index = 23; bit_index >= 0; bit_index --)
            begin
                @(negedge GPIO_0 [4]);
                mic_sd = sample [bit_index];
            end
            @(negedge GPIO_0 [4]);
            mic_sd = 0;
            @(posedge GPIO_0 [2]);
            #1;
            if (dut.i_lab_top.mic !== sample)
                $fatal (1, "INMP441 GPIO/sample path: expected=%h actual=%h",
                        sample, dut.i_lab_top.mic);
        endtask
    `endif

    `ifdef DE25_NANO_USE_I2S_AUDIO
        task capture_audio_sample;
            // The first rising BCLK after a LRCLK transition is the I2S
            // delay bit. The following 16 bits are our left-aligned sample.
            @(posedge GPIO_0 [15]);
            for (int bit_index = 15; bit_index >= 0; bit_index --)
            begin
                @(posedge GPIO_0 [15]);
                captured_audio [bit_index] = GPIO_0 [13];
            end
            if (captured_audio !== lab_sound)
                $fatal (1, "I2S audio sample: expected=%h actual=%h", lab_sound, captured_audio);
            repeat (15)
            begin
                @(posedge GPIO_0 [15]);
                if (GPIO_0 [13] !== 1'b0)
                    $fatal (1, "I2S left-aligned sample padding is nonzero");
            end
        endtask
    `endif

    initial
    begin
        `ifdef DE25_NANO_USE_TM1638
            // Fault injection only at the real controller's key output:
            // this checks wrapper OR/width semantics, not the TM1638 protocol.
            force dut.i_tm1638.keys = tm_keys;
        `endif

        #1;
        SW [3] = 1;
        repeat (4) @(posedge CLOCK1_50);
        @(negedge CLOCK1_50);
        SW [3] = 0;
        repeat (3) @(posedge CLOCK1_50);
        #1;

        check_unused_pins ();

        for (int pattern = 0; pattern < 4; pattern ++)
        begin
            serial_rx = 1' (pattern);
            lab_uart_tx = 1' (pattern >> 1);
            lab_gpio_out = !serial_rx;
            gpio_input = serial_rx;
            #1;
            `ifdef DE25_NANO_USE_UART
                if (dut.i_lab_top.uart_rx !== serial_rx || GPIO_0 [7] !== lab_uart_tx)
                    $fatal (1, "UART RX[6]/TX[7] GPIO mapping or direction failed");
            `else
                if (dut.i_lab_top.uart_rx !== 1'b1 || GPIO_0 [7] !== 1'bz)
                    $fatal (1, "Disabled UART must have idle-high input and undriven TX");
            `endif
            if (GPIO_1 [1] !== lab_gpio_out || dut.i_lab_top.gpio [0] !== gpio_input)
                $fatal (1, "Accessories interfered with the independent lab GPIO header");
        end

        `ifdef DE25_NANO_USE_TM1638
            if ($bits (dut.i_lab_top.key) != 8)
                $fatal (1, "TM1638 must expose eight logical keys");
            for (int keys = 0; keys < 256; keys ++)
            begin
                tm_keys = 8' (keys);
                for (int buttons = 0; buttons < 4; buttons ++)
                begin
                    KEY = 2' (buttons);
                    #1;
                    expected_keys = tm_keys | (8'h03 ^ {6'b0, KEY});
                    if (LEDR !== ~expected_keys)
                        $fatal (1, "TM/onboard key merge: TM=%h KEY=%b LEDR=%h",
                                tm_keys, KEY, LEDR);
                    if (dut.i_tm1638.ledr !== expected_keys)
                        $fatal (1, "TM1638 LEDs must duplicate lab LEDs without inversion");
                end
            end
            for (int segment = 0; segment < 8; segment ++)
            begin
                lab_segments = 8'b1 << segment;
                lab_digits = 8'b1 << segment;
                #1;
                if (dut.i_tm1638.hgfedcba !== (8'b1 << (7 - segment)) ||
                    dut.i_tm1638.digit !== lab_digits)
                    $fatal (1, "TM1638 segment/digit ordering failed");
            end
        `else
            if ($bits (dut.i_lab_top.key) != 2)
                $fatal (1, "No TM1638 must expose exactly two onboard keys");
        `endif

        `ifdef DE25_NANO_USE_INMP441
            if (GPIO_0 [0] !== 1'b0)
                $fatal (1, "INMP441 must select the left channel");
            send_microphone_sample (24'ha5c3f0);
            send_microphone_sample (24'h800001);
            send_microphone_sample (24'h7ffffe);
        `endif

        `ifdef DE25_NANO_USE_I2S_AUDIO
            @(posedge GPIO_0 [17]); edge_time = $time;
            @(posedge GPIO_0 [17]);
            if ($time - edge_time != 80)
                $fatal (1, "Audio MCLK must be 12.5 MHz for a 50 MHz source");
            @(posedge GPIO_0 [15]); edge_time = $time;
            @(posedge GPIO_0 [15]);
            if ($time - edge_time != 320)
                $fatal (1, "Audio BCLK must be MCLK/4");
            @(negedge GPIO_0 [11]);
            capture_audio_sample ();
            @(posedge GPIO_0 [11]);
            capture_audio_sample ();
            lab_sound = 16'h8001;
            @(negedge GPIO_0 [11]);
            capture_audio_sample ();
        `endif

        check_unused_pins ();
        $display ("PASS: ACCESSORIES");
        $finish;
    end

    initial
    begin
        #1000000;
        $fatal (1, "Accessory simulation timed out");
    end
endmodule
