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
  input                  clk,
  input                  rst_n,

  input  [w_key   - 1:0] key_sw_n,
  output [w_led   - 1:0] led_n,

  output [          7:0] abcdefgh_n,
  output [w_digit - 1:0] digit_n,

  output                 hsync,
  output                 vsync,
  output [          2:0] rgb,

  input                  uart_rxd,

  inout  [w_gpio  - 1:0] gpio
);

  //--------------------------------------------------------------------------

  logic [w_led   - 1:0] led;
  logic [          7:0] abcdefgh;
  logic [w_digit - 1:0] digit;

  logic [          3:0] red;
  logic [          3:0] green;
  logic [          3:0] blue;

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
    .clk      (   clk      ),
    .rst      ( ~ rst_n    ),

    .key      ( ~ key_sw_n ),
    .sw       ( ~ key_sw_n ),

    .led      (   led      ),

    .abcdefgh (   abcdefgh ),
    .digit    (   digit    ),

    .vsync    (   vsync    ),
    .hsync    (   hsync    ),

    .red      (   red      ),
    .green    (   green    ),
    .blue     (   blue     ),

    .gpio     (   gpio     )
  );

  //--------------------------------------------------------------------------

  assign led_n      = ~ led;

  assign abcdefgh_n = ~ abcdefgh;
  assign digit_n    = ~ digit;

  assign rgb        = { | red, | green, | blue };

endmodule
