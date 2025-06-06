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

    // START_SOLUTION
    logic [8:0] dx, dy;
    // END_SOLUTION

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        if (x > 100 & x < 300 & y > 50 & y < 100)
            red = 31;

        // 31 is the maximum 5-bit number, 5'b11111

        // Exercise 1: Uncomment the code for a green rectangle
        // that overlaps red rectangle

        /*

        if (x > 150 & x < 350 & y > 70 & y < 120)
            green = 63;

        */

        // 63 is the maximum 6-bit number, 6'b111111

        // Exercise 2: Add a blue rectangle
        // that overlaps both rectangles

        // START_SOLUTION

        if (x > 200 & x < 400 & y > 90 & y < 140)
            blue = 31;

        // END_SOLUTION

        // Exercise 3: Change color with keys

        // START_SOLUTION

        if (x > 100 & x < 300 & y > 50 & y < 100)
            blue = key [0] ? 31 : 0;

        // END_SOLUTION

        // Exercise 4: Change position with keys

        // START_SOLUTION

        dx = key [1] ? 50 : 0;
        dy = key [2] ? 70 : 0;

        if (x > 150 + dx & x < 170 + dx & y > 70 + dy & y < 90 + dy)
            green = 63;

        // END_SOLUTION

        // Exercise 5: Draw a circle

        // START_SOLUTION

        if (x * x + y * y < 10000)
            red = 31;

        // END_SOLUTION
    end

endmodule
