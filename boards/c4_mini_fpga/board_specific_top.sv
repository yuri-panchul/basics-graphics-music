module board_specific_top
# (
    parameter clk_mhz   = 50,
              w_key     = 8,
              w_sw      = 8,
              w_led     = 16,
              w_digit   = 6,
              w_gpio_j7 = 36, // [3..38]
              w_gpio_p1 = 21, // [2..22]
              w_gpio_p2 = 21  // [2..22] TODO do we need to include buzzer and EEPROM?
)
(
    input                    CLK,

    input  [w_key     - 1:0] KEY_N,
    input  [w_sw      - 1:0] SW_N,

    output logic [w_led     - 1:0] LED_N,

    output [            7:0] ABCDEFGH_N,
    output [w_digit   - 1:0] DIGIT_N,

    input                    UART_RX,
    output                   UART_TX,

//    inout  [w_gpio_j7 + 3 - 1:3] GPIO_J7,
    inout  [w_gpio_p1 + 2 - 1:2] GPIO_P1,
    inout  [w_gpio_p2 + 2 - 1:2] GPIO_P2
);
/*
wire rst = SW_N [7];

logic [31:0] cnt;

always @ (posedge CLK or posedge rst)
    if (rst)
        cnt <= '0;
    else
        cnt <= cnt + 1'd1;

assign LED_N = cnt [31:24];
*/
    localparam w_gpio = w_gpio_j7 + w_gpio_p1 + w_gpio_p2;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw - 1 ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk      ( CLK        ),
        .rst      ( SW_N [7]   ),

        .key      ( KEY_N      ),
        .sw       ( SW_N [6:0] ),

        .led      ( LED_N      ),

        .abcdefgh ( ABCDEFGH_N ),
        .digit    ( DIGIT_N    ),

        .gpio     (            )
    );

endmodule
