module board_specific_top
# (
  parameter clk_mhz = 50,
            w_key   = 2,
            w_sw    = 9,  // One sw is used as a reset
            w_led   = 10,
            w_digit = 6,
            w_gpio  = 36
)
(
  input                   max10_clk1_50,

  input  [w_key    - 1:0] key,
  input  [w_sw + 1 - 1:0] sw,  // One sw is used as a reset
  output [w_led    - 1:0] ledr,

  output [           7:0] hex0,
  output [           7:0] hex1,
  output [           7:0] hex2,
  output [           7:0] hex3,
  output [           7:0] hex4,
  output [           7:0] hex5,

  output                  vga_hs,
  output                  vga_vs,
  output [           3:0] vga_r,
  output [           3:0] vga_g,
  output [           3:0] vga_b,

  inout  [          35:0] gpio
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
    .clk      (   max10_clk1_50   ),
    .rst      (   sw [w_sw]       ),

    .key      ( ~ key             ),
    .sw       (   sw [w_sw - 1:0] ),

    .led      (   ledr            ),

    .abcdefgh (   abcdefgh        ),
    .digit    (   digit           ),

    .vsync    (   vga_vs          ),
    .hsync    (   vga_hs          ),

    .red      (   vga_r           ),
    .green    (   vga_g           ),
    .blue     (   vga_b           ),

    .gpio     (   gpio            )
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

  assign hex0 = digit [0] ? ~ hgfedcba : '1;
  assign hex1 = digit [1] ? ~ hgfedcba : '1;
  assign hex2 = digit [2] ? ~ hgfedcba : '1;
  assign hex3 = digit [3] ? ~ hgfedcba : '1;
  assign hex4 = digit [4] ? ~ hgfedcba : '1;
  assign hex5 = digit [5] ? ~ hgfedcba : '1;

endmodule
