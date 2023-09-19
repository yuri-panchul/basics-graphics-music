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

    output [w_led     - 1:0] LED_N,

    output [            7:0] ABCDEFGH_N,
    output [w_digit   - 1:0] DIGIT_N,

    input                    UART_RX,
    output                   UART_TX,

    inout  [w_gpio_j7 + 3 - 1:3] GPIO_J7,
    inout  [w_gpio_p1 + 2 - 1:2] GPIO_P1,
    inout  [w_gpio_p2 + 2 - 1:2] GPIO_P2
);

    //------------------------------------------------------------------------

    wire [w_key   - 1:0] key;
    wire [w_sw    - 1:0] sw;
    wire [w_led   - 1:0] led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

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
        .clk      ( CLK        ),
        .rst      ( rst        ),

        .key      ( key        ),
        .sw       ( key        ),

        .led      ( LED        ),

        .abcdefgh ( abcdefgh   ),
        .digit    ( digit      ),

        .gpio     ( GPIO       )

    );

    //------------------------------------------------------------------------

    assign SEG_DATA  = ~ abcdefgh;
    assign SEG_SEL   = ~ digit;

endmodule
