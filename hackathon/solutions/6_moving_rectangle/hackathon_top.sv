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
    localparam screen_width  = 480,
               screen_height = 272;

    logic pulse;

    strobe_gen # (.clk_mhz (27), .strobe_hz (30))
    i_strobe_gen (clock, reset, pulse);

    logic [7:0] counter;

    always_ff @ (posedge clock)
        if (reset)
        begin
            counter <= 0;
        end
        else if (pulse)
        begin
            if (counter == screen_width / 2)
                counter <= 0;
            else
                counter <= counter + 1;
        end

    always_comb
    begin
        red = 0; green = 0; blue = 0;

        if (  x > 100 + counter & x < 150 + counter
            & y > 100           & y < 200 )
        begin
            red = 31;
        end
    end

    assign led = counter;

    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock    ),
        .rst      ( reset    ),
        .number   ( counter  ),
        .dots     ( 0        ),
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

    // Exercise 1: Make the rectangle moving opposite direction

    // Exercise 2: Make the rectangle moving by keys

    // Exercise 3: Create a game with two rectangles

endmodule
