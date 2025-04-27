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

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        // START_SOLUTION

        if (x > 100 & x < 300 & y > 50 & y < 100)
            red = key [0] ? 5'b11111 : x [6:2];

        if (x > 150 & x < 350 & y > 70 & y < 120)
            green = key [1] ? 6'b111111 : x [7:2];

        if (x > 200 & x < 400 & y > 90 & y < 140)
            blue = key [2] ? 5'b11111 : y [5:1];

        // END_SOLUTION
    end

endmodule
