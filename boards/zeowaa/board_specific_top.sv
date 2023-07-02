// Asynchronous reset here is needed for some FPGA boards we use

module board_specific_top
# (
  parameter clk_mhz = 50,
            w_key   = 3,
            w_sw    = 8,
            w_led   = 12,
            w_digit = 8,
            w_gpio  = 19
)
(
  input                    clk,
  input                    clk_user,
  input                    clk_in_1,
  input                    clk_in_2,

  input  [w_key + 1 - 1:0] key_n,  // One key is used as a reset
  input  [w_sw      - 1:0] sw,
  output [w_led     - 1:0] led_n,

  output [            7:0] abcdefgh_n,
  output [w_digit   - 1:0] digit_n,

  output                   buzzer,

  output                   vga_hsync,
  output                   vga_vsync,
  output [            2:0] vga_rgb,

  inout  [w_gpio    - 1:0] gpio
);

  //--------------------------------------------------------------------------

  assign buzzer = 1'b1;

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
    .clk      (   clk         ),
    .rst      ( ~ key_n [3]   ),

    .key      ( ~ key_n [2:0] ),
    .sw       (   sw          ),

    .led      (   led         ),

    .abcdefgh (   abcdefgh    ),
    .digit    (   digit       ),

    .vsync    (   vga_vsync   ),
    .hsync    (   vga_hsync   ),

    .red      (   red         ),
    .green    (   green       ),
    .blue     (   blue        ),

    .gpio     (   gpio        )
  );

  //--------------------------------------------------------------------------

  assign led_n      = ~ led;

  assign abcdefgh_n = ~ abcdefgh;
  assign digit_n    = ~ digit;

  assign rgb        = { | red, | green, | blue };

endmodule
