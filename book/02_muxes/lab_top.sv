`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
       assign abcdefgh   = '0;
       assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    mux_2_1_using_conditional_operator mux_1
    (
        .a   ( key [1] ),
        .b   ( key [0] ),
        .sel ( key [2] ),
        .out ( led [0] )
    );

    mux_2_1_width_3_using_if mux_2
    (
        .a   ( key [5:3] ),
        .b   ( key [2:0] ),
        .sel ( key [7]   ),
        .out ( led [7:5] )
    );

    mux_5_1_using_case mux_3
    (
        .a   ( key [4]   ),
        .b   ( key [3]   ),
        .c   ( key [2]   ),
        .d   ( key [1]   ),
        .e   ( key [0]   ),
        .sel ( key [7:5] ),
        .out ( led [1]   )
    );

    mux_4_1_using_indexing mux_4
    (
        .in  ( key [3:0] ),
        .sel ( key [7:6] ),
        .out ( led [2]   )
    );

endmodule
