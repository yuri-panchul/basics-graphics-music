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
    output logic [4:0] blue
);

    // Exercise 1: Free running counter.
    // How do you change the speed of LED blinking?
    // Try different bit slices to display.

    logic [7:0] counter;

    always_ff @ (posedge slow_clock)
        if (reset)
            counter <= 0;
        else
            counter <= counter + 1;

    assign led = counter;
/*
    always_comb
    begin
        red = 0;
        green = 0;
        blue = 0;

        if (x < counter)
            red = 31;
    end
*/
/*
    logic old_key;

    always_ff @(posedge clock)
        old_key <= key [0];

    wire change = key [0] == 1 & old_key == 0;

    logic [31:0] counter;

    always_ff @ (posedge clock)
        if (reset)
            counter <= 0;
        else if (change)
            counter <= counter + 1;

    assign led = counter [7:0]; // counter [23:16]; // [31:24];  // Try to put [23:16] here

    // assign led = counter >> 20;  // Try alternative way to shift the value

    // Try to add "if (key)" after "else".

    // Exercise 2: Key-controlled counter.
    // Comment out the code above.
    // Uncomment and synthesize the code below.
    // Press the key to see the counter incrementing.
    //
    // Change the design, for example:
    //
    // 1. One key is used to increment, another to decrement.
    //
    // 2. Two counters controlled by different keys
    // displayed in different groups of LEDs.
*/

endmodule
