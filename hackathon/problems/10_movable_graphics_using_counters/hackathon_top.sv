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

    // Movable graphics using counters

    localparam screen_width  = 480,
               screen_height = 272;

    logic [19:0] c1;

    always_ff @ (posedge clock)
        if (reset)
            c1 <= 0;
        else
            c1 <= c1 + 1;

    assign led = c1 [19:12];

    // 2 ** 20 = (2 ** 10) * (2 ** 10) = 1024 * 1024 = approximate 1000000
    // 27 MHz 27000000 / 2 ** 20 = 27 times a second c1 overflows

    logic [9:0] c2;

    always_ff @ (posedge clock)
        if (reset)
        begin
            c2 <= 0;
        end
        else if (c1 == 0)
        begin
            if (c2 > screen_width)
                c2 = 0;
            else
                c2 <= c2 + 1;
        end

    logic [9:0] c3;

    always_ff @ (posedge clock)
        if (reset)
        begin
            c3 <= 0;
        end
        else if (c1 == 0)
        begin
            if (c3 > screen_height)
                c3 <= 0;
            else
                c3 <= c3 + 10;
        end

    always_comb
    begin    
        red   = 0;
        blue  = 0;
        green = 0;

        if (x > c2)
        begin
            red = 31;
            
            if (key != 0)
                green = 63;
        end

        if (y > c3)
            green = x;

        if (x * x + y * y < 10000)
            blue = 31;
    end

endmodule
