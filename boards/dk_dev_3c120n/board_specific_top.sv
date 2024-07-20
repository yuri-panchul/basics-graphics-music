`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 4,
              w_gpio  = 1
)
(
    input                clkin_50,
    input                clkin_125,
    input                clkin_sma,
    input                clkout_sma,

    input                cpu_resetn,

    input  [w_key - 1:0] user_pb,
    input  [w_sw  - 1:0] user_dipsw,
    output [w_led - 1:0] user_led,

    output               seven_seg_a,
    output               seven_seg_b,
    output               seven_seg_c,
    output               seven_seg_d,
    output               seven_seg_e,
    output               seven_seg_f,
    output               seven_seg_g,
    output               seven_seg_dp,
    output               seven_seg_minus,

    output [w_digit  :1] seven_seg_sel,

    output               speaker_out
);

    assign seven_seg_minus = '0;
    assign speaker_out     = '0;

    //------------------------------------------------------------------------

    wire clk = clkin_50;
    wire rst = ~ cpu_resetn;

    //------------------------------------------------------------------------

    wire [w_led - 1:0] led;
    assign user_led = ~ led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    // FIXME: Should be assigned to some GPIO!
    wire                 UART_TX;
    wire                 UART_RX = '1;

    assign
    {
        seven_seg_a,
        seven_seg_b,
        seven_seg_c,
        seven_seg_d,
        seven_seg_e,
        seven_seg_f,
        seven_seg_g,
        seven_seg_dp
    }
    = ~ abcdefgh;

    assign seven_seg_sel = { digit [0], digit [1], digit [2], digit [3] };

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_lab_top
    (
        .clk      (   clk         ),
        .slow_clk (   slow_clk    ),
        .rst      (   rst         ),

        .key      ( ~ user_pb     ),
        .sw       (   user_dipsw  ),

        .led      (   led         ),

        .abcdefgh (   abcdefgh    ),
        .digit    (   digit       ),

        .vsync    (               ),
        .hsync    (               ),

        .red      (               ),
        .green    (               ),
        .blue     (               ),

        .uart_rx  (   UART_RX     ),
        .uart_tx  (   UART_TX     ),

        .mic      (               ),
        .gpio     (               )
    );

endmodule
