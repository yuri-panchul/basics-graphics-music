
module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 5,
                w_sw    = 5,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 32
)
(
    input                       CLK,
    input                       RESET,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3
);

    //------------------------------------------------------------------------

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
        .clk      (   CLK        ),
        .rst      ( ~ RESET        ),

        .key      (   KEY          ),
        .sw       ( ~ SW           ),

        .led      (   LED          ),

        .abcdefgh (                ),
        .digit    (                ),

        .vsync    (                ),
        .hsync    (                ),

        .red      (                ),
        .green    (                ),
        .blue     (                ),

        .mic      (                ),
        .gpio     (   GPIO         )
    );

endmodule