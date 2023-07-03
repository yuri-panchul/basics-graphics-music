// Asynchronous reset here is needed for some FPGA boards we use

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

  inout  [w_gpio  - 1:0] GPIO
);

  //--------------------------------------------------------------------------

  wire [w_led   - 1:0] led;

  wire [          7:0] abcdefgh;
  wire [w_digit - 1:0] digit;

  wire [          3:0] red, green, blue;

  //--------------------------------------------------------------------------

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

    .gpio     (   GPIO      )
  );

  //--------------------------------------------------------------------------

  assign LED   = ~ led;

  assign SEG   = ~ abcdefgh;
  assign DIG   = ~ digit;

  assign VGA_R = | red;
  assign VGA_G = | green;
  assign VGA_B = | blue;

endmodule
