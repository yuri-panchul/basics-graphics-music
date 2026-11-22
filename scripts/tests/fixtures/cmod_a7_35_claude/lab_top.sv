// A test lab for the Cmod A7 configurations of Claude: constant colors, a
// constant sound sample and a constant GPIO pattern, the keys on the LEDs and
// the UART looped back, so that tb.sv can check every pin of the board.

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

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    inout        [w_gpio  - 1:0] gpio
);

    assign led      = w_led'   (key);
    assign abcdefgh = 8'b1000_0000;
    assign digit    = w_digit' (1);

    assign red      = w_red'   (2'b10);
    assign green    = w_green' (2'b01);
    assign blue     = w_blue'  (2'b11);

    assign sound    = 16'h5a3c;
    assign uart_tx  = uart_rx;
    assign gpio     = w_gpio'  (64'h9c5a_3e71_d2b6_48a6);

endmodule
