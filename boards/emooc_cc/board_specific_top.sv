// This board is referred as "MINI FPGA", EPI-MiniCY4
// and as a part of a kit called EPI-LITE304.
//
// See http://emooc.cc
// and http://www.emooc.cc/ProductDetail/1600208.html
// for more details.

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

    wire clk = CLK;

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

    // Microphone works by I2S protocol, assembling virtual 24 bits one by one
    wire [                   23:0] mic;
    wire                           mic_ready;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    // "top" module is a parametrized type, here are numeric parameters
    top
    # (
        .clk_mhz ( clk_mhz  ),
        .w_key   ( w_key    ),
        .w_sw    ( w_top_sw ), // only non-reset switches used as inputs
        .w_led   ( w_led    ),
        .w_digit ( w_digit  ),
        .w_gpio  ( w_gpio   )
    )
    // i_top is an instance, passing signal mappings - ?..
    i_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( ~ KEY_N   ), // invert keys, bringing to standard
        .sw       ( top_sw    ),

        .led      ( LED       ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( digit     ),

        .vsync    ( vga_vs    ),
        .hsync    ( vga_hs    ),

        .red      ( vga_red   ),
        .green    ( vga_green ),
        .blue     ( vga_blue  ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .mic      ( mic       ),
        .mic_ready( mic_ready ),
        .gpio     (           )
    );

    assign ABCDEFGH = abcdefgh;
    assign DIGIT_N  = ~ digit;

    // VGA out at GPIO
    assign GPIO_P1 [2]  = vga_vs;        // PIN_C6
    assign GPIO_P1 [3]  = vga_hs;        // PIN_B6
    // R
    assign GPIO_P1 [4]  = vga_red [3];   // PIN_A6
    assign GPIO_P1 [5]  = vga_red [2];   // PIN_B7
    assign GPIO_P1 [6]  = vga_red [1];   // PIN_A7
    assign GPIO_P1 [7]  = vga_red [0];   // PIN_B8
    // G
    assign GPIO_P1 [8]  = vga_green [3]; // PIN_A8
    assign GPIO_P1 [9]  = vga_green [2]; // PIN_A9
    assign GPIO_P1 [10] = vga_green [1]; // PIN_B9
    assign GPIO_P1 [11] = vga_green [0]; // PIN_A11
    // B
    assign GPIO_P1 [12] = vga_blue [3];  // PIN_B11
    assign GPIO_P1 [13] = vga_blue [2];  // PIN_A12
    assign GPIO_P1 [14] = vga_blue [1];  // PIN_B12
    assign GPIO_P1 [15] = vga_blue [0];  // PIN_A13

    // type - without parameters - and an instance of a microphone
    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk          ),
        .rst   ( rst          ),
        .lr    ( GPIO_P1 [16] ), // PIN_B13
        .ws    ( GPIO_P1 [17] ), // PIN_A14
        .sck   ( GPIO_P1 [18] ), // PIN_B14
        .sd    ( GPIO_P1 [19] ), // PIN_A15
        .ready ( mic_ready    ),
        .value ( mic          )
    );

endmodule
