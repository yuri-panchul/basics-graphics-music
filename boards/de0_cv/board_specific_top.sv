module board_specific_top
# (
  parameter clk_mhz = 50,
            w_key   = 4,
            w_sw    = 9,  // One sw is used as a reset
            w_led   = 10,
            w_digit = 6,
            w_gpio  = 36
)
(
  input                   CLK,

  input  [w_key    - 1:0] KEY,
  input  [w_sw + 1 - 1:0] SW,  // One sw is used as a reset
  output [w_led    - 1:0] LEDR,

  output [           7:0] HEX0,
  output [           7:0] HEX1,
  output [           7:0] HEX2,
  output [           7:0] HEX3,
  output [           7:0] HEX4,
  output [           7:0] HEX5,

  output                  VGA_HS,
  output                  VGA_VS,
  output [           3:0] VGA_R,
  output [           3:0] VGA_G,
  output [           3:0] VGA_B,

  inout  [w_gpio   - 1:0] GPIO
);

  //--------------------------------------------------------------------------

  wire [          7:0] abcdefgh;
  wire [w_digit - 1:0] digit;

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
    .clk      (   CLK  ),
    .rst      (   SW [w_sw]       ),

    .key      ( ~ KEY             ),
    .sw       (   SW [w_sw - 1:0] ),

    .led      (   LEDR            ),

    .abcdefgh (   abcdefgh        ),
    .digit    (   digit           ),

    .vsync    (   VGA_VS          ),
    .hsync    (   VGA_HS          ),

    .red      (   VGA_R           ),
    .green    (   VGA_G           ),
    .blue     (   VGA_B           ),

    .gpio     (   GPIO            )
  );

  //--------------------------------------------------------------------------

  wire [$left (abcdefgh):0] hgfedcba;

  generate
    genvar i;

    for (i = 0; i < $bits (abcdefgh); i ++)
    begin : abc
      assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
    end
  endgenerate

  assign HEX0 = digit [0] ? ~ hgfedcba : '1;
  assign HEX1 = digit [1] ? ~ hgfedcba : '1;
  assign HEX2 = digit [2] ? ~ hgfedcba : '1;
  assign HEX3 = digit [3] ? ~ hgfedcba : '1;
  assign HEX4 = digit [4] ? ~ hgfedcba : '1;
  assign HEX5 = digit [5] ? ~ hgfedcba : '1;

endmodule
