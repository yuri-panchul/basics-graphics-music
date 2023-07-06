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
  input                    CLK,

  input  [w_key + 1 - 1:0] KEY_N,  // One key is used as a reset
  input  [w_sw      - 1:0] SW_N,
  output [w_led     - 1:0] LED_N,

  output [            7:0] ABCDEFGH_N,
  output [w_digit   - 1:0] DIGIT_N,

  output                   VGA_HSYNC,
  output                   VGA_VSYNC,
  output [            2:0] VGA_RGB,

  input                    UART_RX,

  inout  [w_gpio    - 1:0] GPIO
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
    .clk      (   CLK         ),
    .rst      ( ~ KEY_N [3]   ),

    .key      ( ~ KEY_N [2:0] ),
    .sw       ( ~ SW_N        ),

    .led      (   led         ),

    .abcdefgh (   abcdefgh    ),
    .digit    (   digit       ),

    .vsync    (   VGA_VSYNC   ),
    .hsync    (   VGA_HSYNC   ),

    .red      (   red         ),
    .green    (   green       ),
    .blue     (   blue        ),

    .gpio     (   GPIO        )
  );

  //--------------------------------------------------------------------------

  assign LED_N      = ~ led;

  assign ABCDEFGH_N = ~ abcdefgh;
  assign DIGIT_N    = ~ digit;

  assign VGA_RGB    = { | red, | green, | blue };

endmodule
