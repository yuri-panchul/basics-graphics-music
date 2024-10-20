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
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    // Exercise 1. Synthesize the counter controlled by two keys.
    // When one key is in pressed position - the frequency increases,
    // when another key is in pressed position - the frequency decreases.
    // Change the period increment / decrement and see what happens.

    logic [31:0] period;

    localparam min_period = clk_mhz * 1000 * 1000 / 50,
               max_period = clk_mhz * 1000 * 1000 *  3;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            period <= 32' ((min_period + max_period) / 2);
        else if (key [0] & period != max_period)
            period <= period + 32'h1;
        else if (key [1] & period != min_period)
            period <= period - 32'h1;

    logic [31:0] cnt_1;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_1 <= '0;
        else if (cnt_1 == '0)
            cnt_1 <= period - 1'b1;
        else
            cnt_1 <= cnt_1 - 1'd1;

    logic [31:0] cnt_2;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_2 <= '0;
        else if (cnt_1 == '0)
            cnt_2 <= cnt_2 + 1'd1;

    assign led = cnt_2;

    //------------------------------------------------------------------------

    // 4 bits per hexadecimal digit
    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .number   ( w_display_number' (cnt_2) ),
        .dots     ( w_digit' (0)              ),
        .abcdefgh ( abcdefgh                  ),
        .digit    ( digit                     )
    );

    //------------------------------------------------------------------------

    // Exercise 2: Change the example above to:
    //
    // 1. Double the frequency when one key is pressed and released.
    // 2. Halve the frequency when another key is pressed and released.

endmodule
