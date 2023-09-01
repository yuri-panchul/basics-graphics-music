module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 2,  // The last key is used for a reset
                w_sw    = 0,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 0
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio      - 1:0]  GPIO
);

    localparam w_top_key = w_key - 1;

    wire                   rst     = ~ KEY [w_key - 1];
    wire [w_top_key - 1:0] top_key = ~ KEY [w_top_key - 1:0];

    //------------------------------------------------------------------------

    wire [w_led  - 1:0] led;
    wire [w_gpio - 1:0] gpio;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz   ),
        .w_key   ( w_top_key ),  // The last key is used for a reset
        .w_sw    ( w_sw      ),
        .w_led   ( w_led     ),
        .w_digit ( w_digit   ),
        .w_gpio  ( w_gpio    )
    )
    i_top
    (
        .clk      (   CLK     ),
        .rst      (   rst     ),

        .key      (   top_key ),
        .sw       (           ),

        .led      (   led     ),

        .abcdefgh (           ),
        .digit    (           ),

        .vsync    (           ),
        .hsync    (           ),

        .red      (           ),
        .green    (           ),
        .blue     (           ),

        .mic      (           ),
        .gpio     (   gpio    )
    );

    //------------------------------------------------------------------------

    assign LED = ~ led;

endmodule
