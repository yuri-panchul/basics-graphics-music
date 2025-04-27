// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);

    //------------------------------------------------------------------------

    // Exercise 1. Synthesize the counter controlled by two keys.
    // When one key is in pressed position - the frequency increases,
    // when another key is in pressed position - the frequency decreases.
    // Change the period increment / decrement and see what happens.

    logic [31:0] period;

    localparam clock_frequency = 27000000,  // 27 MHz
               min_period = clock_frequency / 50,
               max_period = clock_frequency * 3;

    always_ff @ (posedge clock)
        if (reset)
            period <= (min_period + max_period) / 2;
        else if (key [0] & period != max_period)
            period <= period + 1;
        else if (key [1] & period != min_period)
            period <= period - 1;

    logic [31:0] counter_1;

    always_ff @ (posedge clock)
        if (reset)
            counter_1 <= 0;
        else if (counter_1 == 0)
            counter_1 <= period - 1;
        else
            counter_1 <= counter_1 - 1'd1;

    logic [31:0] counter_2;

    always_ff @ (posedge clock)
        if (reset)
            counter_2 <= 0;
        else if (counter_1 == 0)
            counter_2 <= counter_2 + 1;

    assign led = counter_2;

    //------------------------------------------------------------------------

    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock     ),
        .rst      ( reset     ),
        .number   ( counter_2 ),
        .dots     ( 0         ),
        .abcdefgh ( abcdefgh  ),
        .digit    ( digit     )
    );

    //------------------------------------------------------------------------

    // Exercise 2: Change the example above to:
    //
    // 1. Double the frequency when one key is pressed and released.
    // 2. Halve the frequency when another key is pressed and released.

    // START_SOLUTION
    // END_SOLUTION

endmodule
