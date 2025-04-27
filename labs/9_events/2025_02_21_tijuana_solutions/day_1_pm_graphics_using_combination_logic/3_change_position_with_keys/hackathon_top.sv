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

    wire [8:0] dx = key [0] ? 100 : 0;

    logic [8:0] dy;

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        // START_SOLUTION

        dy = key [7:1];

        if (x > 100 & x < 300 + dx & y > 50 & y < 100)
            red = 31;

        if (x > 150 - dx & x < 350 - dx & y > 70 & y < 120)
            green = 63;

        if (x > 200 & x < 400 & y > 90 + dy & y < 140 + dy)
            blue = 31;

        // END_SOLUTION
    end

endmodule
