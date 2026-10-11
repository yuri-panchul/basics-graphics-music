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
    board_specific_top dut (.MIC_SD(1'b0), .UART_RX(1'b1), .*);

    initial
    begin
        #100000;

        if (dut.rst !== 0 || FLASH_CSB !== 1 || UART_TX !== 1 || LED !== 6'b111111)
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
