module board_specific_top
# (
    // numeric constants, generally useful to describe the board
    parameter clk_mhz   = 50,
              w_key     = 8,
              w_sw      = 8,
              w_led     = 16,
              w_digit   = 6,
              w_gpio_j7 = 36, // [3..38]
              w_gpio_p1 = 21, // [2..22]
              w_gpio_p2 = 21  // [2..22]
              // we do not currently include buzzer and EEPROM
)
(
    // declare input signals - clock, buttons...
    input                    CLK,

    input  [w_key     - 1:0] KEY_N, // "negative" logic - low when pressed
    input  [w_sw      - 1:0] SW,

    // declare output signals - LEDs, 8-segment indicator...
    output [w_led     - 1:0] LED,

    output [            7:0] ABCDEFGH,
    output [w_digit   - 1:0] DIGIT_N,

    // declare both UART lines, input and output
    input                    UART_RX,
    output                   UART_TX,

    // GPIO
//    inout  [w_gpio_j7 + 3 - 1:3] GPIO_J7,
    inout  [w_gpio_p1 + 2 - 1:2] GPIO_P1,
    inout  [w_gpio_p2 + 2 - 1:2] GPIO_P2
);

    // locally useful numeric constants
    localparam w_gpio   = w_gpio_j7 + w_gpio_p1 + w_gpio_p2,
               w_top_sw = w_sw - 1;

    // one switch is used as reset, others - as input signals;
    // for convenience, declare set of wires "top_sw"
    wire                  rst    = SW [w_sw - 1];
    wire [w_top_sw - 1:0] top_sw = SW [w_top_sw - 1:0];

    //------------------------------------------------------------------------

    // calling "top" module and passing numeric parameters
    top
    # (
        .clk_mhz ( clk_mhz  ),
        .w_key   ( w_key    ),
        .w_sw    ( w_top_sw ), // only non-reset switches used as inputs
        .w_led   ( w_led    ),
        .w_digit ( w_digit  ),
        .w_gpio  ( w_gpio   )
    )
    // and also passing signal mappings - ?..
    i_top
    (
        .clk      ( CLK        ),
        .rst      ( rst        ),

        .key      ( ~ KEY_N    ), // invert keys, bringing to standard
        .sw       ( top_sw     ),

        .led      ( LED        ),

        .abcdefgh ( ABCDEFGH   ),
        .digit    ( ~ DIGIT_N  ),

        .gpio     (            )
    );

endmodule
