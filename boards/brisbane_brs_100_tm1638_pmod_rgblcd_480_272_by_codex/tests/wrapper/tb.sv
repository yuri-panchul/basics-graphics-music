`timescale 1ns / 1ps
`include "lab_specific_board_config.svh"
`include "brs100_config.svh"

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

// Ideal clock model for wrapper integration. This does not validate analog
// PLL behavior; synthesis/place-and-route uses the real brs100_pll.v.
module brs100_pll (input clkin, output logic clkout = 0, output logic locked = 0);
    integer divider = 0;

    `ifdef BRS100_LAB_USES_PIXEL_CLOCK
    always #(500.0 / `BRS100_PIXEL_MHZ) clkout = ~clkout;
    `else
    always @ (clkin)
        if (divider == 2)
        begin
            clkout = ~clkout;
            divider = 0;
        end
        else
            divider = divider + 1;
    `endif

    initial #500 locked = 1;
endmodule

module tb;
    logic CLK = 0;
    always #18.5185185 CLK = ~CLK;
    logic [1:0] KEY = 2'b11;
    wire [5:0] LED;
    wire LCD_CLK, LCD_DE, LCD_HS, LCD_VS;
    wire [4:0] LCD_R, LCD_B;
    wire [5:0] LCD_G;
    tri1 TM_DIO;
    wire TM_CLK, TM_STB, MIC_WS, MIC_SCK, DAC_BCK, DAC_DIN, DAC_LRCK;
    wire [2:0] GPIO;
    wire UART_TX, FLASH_CSB;
    tri [32:1] pad_io;
    `ifdef BRS100_PIN_MAPPING_TEST
        assign pad_io[26] = mic_drive;
    `else
        assign pad_io[26] = 1'b0;
    `endif
    pullup (pad_io[21]);
    assign {LCD_DE,LCD_VS,LCD_HS,LCD_CLK,LCD_B,LCD_G,LCD_R} = pad_io[20:1];
    assign {TM_STB,TM_CLK} = pad_io[23:22];
    assign {MIC_SCK,MIC_WS} = pad_io[25:24];
    assign {DAC_LRCK,DAC_DIN,DAC_BCK} = pad_io[29:27];
    wire FLASH_CLK, FLASH_MOSI;
    board_specific_top dut
    (
        .pad_clk_27Mhz(CLK), .pad_user_buttons_n(KEY), .pad_leds_n(LED),
        .pad_ser_rx(1'b1), .pad_ser_tx(UART_TX), .pad_io(pad_io),
        .pad_flash_clk(FLASH_CLK), .pad_flash_csb(FLASH_CSB),
        .pad_flash_mosi(FLASH_MOSI), .pad_flash_miso(1'b1)
    );

    `ifdef BRS100_PIN_MAPPING_TEST
        // Test the header boundary, independently of the CST names. Drive
        // every output bit in turn, then exercise input and bidirectional nets.
        logic [29:1] pattern;
        logic mic_drive = 0;
        logic tm_drive = 1'bz;
        logic [2:0] external_gpio = 'z, lab_gpio = 'z;
        assign pad_io[21] = tm_drive;
        assign pad_io[32:30] = external_gpio;
        assign dut.i_lab_top.gpio = lab_gpio;

        initial
        begin
            for (integer n = 0; n <= 29; n = n + 1)
            begin
                pattern = n == 0 ? '0 : 29'b1 << (n - 1);
                force dut.LCD_R = pattern[5:1];
                force dut.LCD_G = pattern[11:6];
                force dut.LCD_B = pattern[16:12];
                force dut.LCD_CLK = pattern[17];
                force dut.LCD_HS = pattern[18];
                force dut.LCD_VS = pattern[19];
                force dut.LCD_DE = pattern[20];
                force dut.i_tm1638.tm_rw = 1;
                force dut.i_tm1638.dio_out = pattern[21];
                force dut.TM_CLK = pattern[22];
                force dut.TM_STB = pattern[23];
                force dut.MIC_WS = pattern[24];
                force dut.MIC_SCK = pattern[25];
                mic_drive = pattern[26];
                force dut.DAC_BCK = pattern[27];
                force dut.DAC_DIN = pattern[28];
                force dut.DAC_LRCK = pattern[29];
                #1;

                if (pad_io[29:1] !== pattern || dut.i_microphone.sd !== mic_drive)
                    $fatal(1, "GPIO output/input mapping failed at walking bit %0d", n);
            end

            force dut.i_tm1638.tm_rw = 0;

            for (integer value = 0; value < 2; value = value + 1)
            begin
                tm_drive = 1'(value);
                #1;

                if (dut.i_tm1638.dio_in !== tm_drive || pad_io[21] !== tm_drive)
                    $fatal(1, "TM1638 input path or tristate release failed");
            end

            tm_drive = 1'bz;
            #1;

            if (pad_io[21] !== 1)
                $fatal(1, "Released TM1638 DIO did not reach its pullup");

            for (integer value = 0; value < 8; value = value + 1)
            begin
                external_gpio = 3'(value);
                #1;

                if (dut.i_lab_top.gpio !== external_gpio)
                    $fatal(1, "Spare GPIO input mapping failed");
            end

            external_gpio = 'z;

            for (integer value = 0; value < 8; value = value + 1)
            begin
                lab_gpio = 3'(value);
                #1;

                if (pad_io[32:30] !== lab_gpio)
                    $fatal(1, "Spare GPIO output mapping failed");
            end

            lab_gpio = 'z;
            #1;

            if (pad_io[32:30] !== 3'bzzz)
                $fatal(1, "Spare GPIO tristate release failed");

            release dut.LCD_R;
            release dut.LCD_G;
            release dut.LCD_B;
            release dut.LCD_CLK;
            release dut.LCD_HS;
            release dut.LCD_VS;
            release dut.LCD_DE;
            release dut.i_tm1638.tm_rw;
            release dut.i_tm1638.dio_out;
            release dut.TM_CLK;
            release dut.TM_STB;
            release dut.MIC_WS;
            release dut.MIC_SCK;
            release dut.DAC_BCK;
            release dut.DAC_DIN;
            release dut.DAC_LRCK;
            mic_drive = 0;
            $display("PASS GPIO mapping: walking bits, inputs and bidirectional release");
        end
    `endif

    initial
    begin
        #100000;

        if ({FLASH_CLK,FLASH_MOSI} !== 2'b00 || dut.rst !== 0 || FLASH_CSB !== 1 || UART_TX !== 1 || LED !== 6'b111111)
            $fatal(1, "Reset, flash, UART or LED integration failed");

        if ((^ {LCD_CLK,LCD_DE,LCD_HS,LCD_VS,LCD_R,LCD_G,LCD_B,
                TM_CLK,TM_STB,MIC_WS,MIC_SCK,DAC_BCK,DAC_DIN,DAC_LRCK}) === 1'bx)
            $fatal(1, "An interface is undriven");

        `ifndef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
            if ({LCD_DE,LCD_R,LCD_G,LCD_B,dut.x,dut.y} !== 0)
                $fatal(1, "Disabled graphics not parked");
        `endif

        `ifndef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
            if ({MIC_WS,MIC_SCK,dut.mic} !== 0)
                $fatal(1, "Disabled microphone not parked");
        `endif

        `ifndef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
            if ({DAC_BCK,DAC_DIN,DAC_LRCK} !== 0)
                $fatal(1, "Disabled DAC not parked");
        `endif

        KEY = 2'b10;
        #500;

        `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
            if (dut.rst !== 1)
                $fatal(1, "Board button did not reset TM1638 configuration");
        `else
            if (dut.rst !== 0 || dut.lab_key !== 2'b01 || {TM_CLK,TM_STB} !== 2'b11)
                $fatal(1, "Standalone keys or disabled TM1638 failed");
        `endif

        KEY = 2'b11;
        #1000;

        if (dut.rst !== 0)
            $fatal(1, "Reset did not release");

        $display("PASS wrapper: enabled/disabled interfaces and button behavior");
        $finish;
    end
endmodule
