`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz  = 50,
              w_key    = 2,
              w_sw     = 3,
              w_led    = 8,
              w_digit  = 0,
              w_gpio   = 0
)
(

    //-------------------------------------------------------------------------
    // PLL interface
    //-------------------------------------------------------------------------

    input   clk,
//    input   pll_locked,
//    output  pll_reset_n,

    //-------------------------------------------------------------------------
    //  button
    //-------------------------------------------------------------------------

    input                   rst_button,

    input   [w_key - 1: 0]  keys,

    input   [w_sw - 1: 0]   sw,
    //-------------------------------------------------------------------------
    //  LED
    //-------------------------------------------------------------------------

    output  [w_led - 1: 0]  led_n,

    //-------------------------------------------------------------------------
    //  UART
    //-------------------------------------------------------------------------

    input                   RXD,
    output logic            TXD
);

    wire [w_led - 1: 0]     led;

    //------------------------------------------------------------------------

//    wire                    clk = pll_clk;

    wire                    rst = ~ rst_button;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.clk (clk), .rst (rst), .slow_clk (slow_clk));

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz   ( clk_mhz     ),
        .w_key     ( w_key       ),
        .w_sw      ( w_sw        ),
        .w_led     ( w_led       ),
        .w_digit   ( w_digit     ),
        .w_gpio    ( w_gpio      )
    )
    i_lab_top
    (
        .clk       ( clk         ),
        .slow_clk  ( slow_clk    ),
        .rst       ( rst         ),

        .key       ( keys        ),
        .sw        ( sw          ),

        .led       ( led         ),

        .abcdefgh  (             ),
        .digit     (             ),

        .vsync     (             ),
        .hsync     (             ),

        .red       (             ),
        .green     (             ),
        .blue      (             ),

        .uart_rx   ( RXD         ),
        .uart_tx   ( TXD         ),

        .mic       (             ),
        .sound     (             ),

        .gpio      (             )
    );

    assign led_n = ~ led;

endmodule
