module board_specific_top
# (
  parameter clk_mhz = 50,
            w_key   = 4,
            w_sw    = 10,
            w_led   = 18,
            w_digit = 4,
            w_gpio  = 22
)
(
  input                 clock_50_b8a,
  input                 cpu_reset_n,

  input  [w_key  - 1:0] key,
  input  [w_sw   - 1:0] sw,
  output [         9:0] ledr,
  output [         7:0] ledg,

  output [         7:0] hex0,
  output [         7:0] hex1,
  output [         7:0] hex2,
  output [         7:0] hex3,

  output                vga_hs,
  output                vga_vs,
  output [         3:0] vga_r,
  output [         3:0] vga_g,
  output [         3:0] vga_b,

  input                 uart_rx,

  inout  [w_gpio - 1:0] gpio
);

  //--------------------------------------------------------------------------

  wire [w_led   - 1:0] led;

  assign { ledr, ledg } = led;

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
    .clk      (   clock_50_b8a ),
    .rst      ( ~ cpu_reset_n  ),

    .key      ( ~ key          ),
    .sw       (   sw           ),

    .led      (   led          ),

    .abcdefgh (   abcdefgh     ),
    .digit    (   digit        ),

    .vsync    (   vga_vs       ),
    .hsync    (   vga_hs       ),

    .red      (   vga_r        ),
    .green    (   vga_g        ),
    .blue     (   vga_b        ),

    .gpio     (   gpio         )
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

endmodule
