`include "config.svh"
`include "lab_specific_config.svh"

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

    output logic [            7:0] ABCDEFGH,
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

    // need explicit wire to be able to invert
    wire  [          7:0] abcdefgh;
    wire  [w_digit - 1:0] digit;

    // VGA wires
    wire                           vga_vs, vga_hs;
    wire [                    3:0] vga_red,vga_green,vga_blue;

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

        .abcdefgh ( abcdefgh   ),
        .digit    ( digit      ),

        .vsync    (   vga_vs    ),
        .hsync    (   vga_hs    ),

        .red      (   vga_red   ),
        .green    (   vga_green ),
        .blue     (   vga_blue  ),

        .gpio     (            )
    );

    assign ABCDEFGH = abcdefgh;
    assign DIGIT_N  = ~ digit;

    // VGA out at GPIO
    assign GPIO_P1 [3]  = vga_vs;        // PIN_B6
    assign GPIO_P1 [4]  = vga_hs;        // PIN_A6
    // R
    assign GPIO_P1 [6] = vga_red [3];    // PIN_A7
    assign GPIO_P1 [7] = vga_red [2];    // PIN_B8
    assign GPIO_P1 [8] = vga_red [1];    // PIN_A8
    assign GPIO_P1 [9] = vga_red [0];    // PIN_A9
    // G
    assign GPIO_P1 [11] = vga_green [3]; // PIN_A11
    assign GPIO_P1 [12] = vga_green [2]; // PIN_B11
    assign GPIO_P1 [13] = vga_green [1]; // PIN_A12
    assign GPIO_P1 [14] = vga_green [0]; // PIN_B12
    // B
    assign GPIO_P1 [16] = vga_blue [3];  // PIN_B13
    assign GPIO_P1 [17] = vga_blue [2];  // PIN_A14
    assign GPIO_P1 [18] = vga_blue [1];  // PIN_B14
    assign GPIO_P1 [19] = vga_blue [0];  // PIN_A15

endmodule
