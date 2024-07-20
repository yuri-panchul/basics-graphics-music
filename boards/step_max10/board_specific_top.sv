`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz    = 12,
              w_key      = 4,
              w_sw       = 4,
              w_digit    = 0,
              w_led      = 8,
              w_gpio     = 36
)
(
    input                clk_in,

    input  [w_key - 1:0] BTN,
    input  [w_sw  - 1:0] SW,
    output [w_led - 1:0] WAT_LED,
    output [        8:0] SEG_LED1,
    output [        8:0] SEG_LED2,

    inout  [       35:0] GPIO
);

    //------------------------------------------------------------------------

    localparam w_lab_sw = w_sw - 1;  // One onboard SW is used as a reset

    wire                  clk = clk_in;

    wire                  rst    = SW [w_lab_sw];
    wire [w_lab_sw - 1:0] lab_sw = SW [w_lab_sw - 1:0];
    wire [w_key    - 1:0] lab_key = ~ BTN;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz  ),
        .w_key   ( w_key    ),
        .w_sw    ( w_lab_sw ),
        .w_led   ( w_led    ),
        .w_digit ( w_digit  ),
        .w_gpio  ( w_gpio   )
    )
    i_lab_top
    (
        .clk      (   clk                  ),
        .slow_clk (   slow_clk             ),
        .rst      (   rst                  ),

        .key      (   lab_key              ),
        .sw       (   lab_sw               ),

        .led      (   WAT_LED              ),

        .gpio     (   GPIO                 )
    );

endmodule
