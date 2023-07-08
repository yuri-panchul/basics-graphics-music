// Asynchronous reset here is needed for some FPGA boards we use

`define USE_INMP_441_MIC_ON_OLD_POSITION

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 4,
              w_led   = 4,
              w_digit = 4,
              w_gpio  = 14
)
(
    input                  CLK,
    input                  RESET,

    input  [w_key   - 1:0] KEY,
    output [w_led   - 1:0] LED,

    output [          7:0] SEG,
    output [w_digit - 1:0] DIG,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output                 VGA_R,
    output                 VGA_G,
    output                 VGA_B,

    input                  UART_RXD,

    inout  [w_gpio  - 1:0] GPIO,  // This is not really a GPIO

    inout                  LCD_RS,
    inout                  LCD_RW,
    inout                  LCD_E,
    inout  [          7:0] LCD_D
);

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [          3:0] red, green, blue;
    wire [         23:0] mic;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk      (   CLK       ),
        .rst      ( ~ RESET     ),

        .key      ( ~ KEY       ),
        .sw       ( ~ KEY       ),

        .led      (   led       ),

        .abcdefgh (   abcdefgh  ),
        .digit    (   digit     ),

        .vsync    (   VGA_VSYNC ),
        .hsync    (   VGA_HSYNC ),

        .red      (   red       ),
        .green    (   green     ),
        .blue     (   blue      ),

        .mic      (   mic       ),

        .gpio     (   GPIO      )
    );

    //------------------------------------------------------------------------

    assign LED   = ~ led;

    assign SEG   = ~ abcdefgh;
    assign DIG   = ~ digit;

    assign VGA_R = | red;
    assign VGA_G = | green;
    assign VGA_B = | blue;

    //------------------------------------------------------------------------

    `ifdef USE_OBSOLETE_DIGILENT_MIC

    wire [15:0] mic_16;

    digilent_pmod_mic3_spi_receiver i_microphone
    (
        .clk   ( clk       ),
        .rst   ( rst       ),
        .cs    ( GPIO  [0] ),
        .sck   ( GPIO  [6] ),
        .sdo   ( GPIO  [4] ),
        .value ( mic_16    )
    );

    assign GPIO [ 8] = 1'b0;  // GND
    assign GPIO [10] = 1'b1;  // VCC

    assign mic = { mic_16, 8'b0 };

    //------------------------------------------------------------------------

    `elsif USE_INMP_441_MIC_ON_OLD_POSITION

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk       ),
        .rst   ( rst       ),
        .lr    ( GPIO  [5] ),
        .ws    ( GPIO  [3] ),
        .sck   ( GPIO  [1] ),
        .sd    ( GPIO  [0] ),
        .value ( mic       )
    );

    assign GPIO [4] = 1'b0;  // GND
    assign GPIO [2] = 1'b1;  // VCC

    //------------------------------------------------------------------------

    `else  // USE_INMP_441_MIC

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk       ),
        .rst   ( rst       ),
        .lr    ( LCD_D [1] ),
        .ws    ( LCD_D [2] ),
        .sck   ( LCD_D [3] ),
        .sd    ( LCD_D [6] ),
        .value ( mic       )
    );

    assign LCD_D [4] = 1'b0;  // GND
    assign LCD_D [5] = 1'b1;  // VCC

    `endif

endmodule
