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

    wire [15:0] distance;

    ultrasonic_distance_sensor
    # (
        .clk_frequency ( 27 * 1000 * 1000 ),
        .relative_distance_width ($bits (distance))
    )
    i_sensor
    (
        .clk               ( clock    ),
        .rst               ( reset    ),
        .trig              ( gpio [0] ),
        .echo              ( gpio [1] ),
        .relative_distance ( distance )
    );

    seven_segment_display
    # (.w_digit (8))
    i_7segment
    (
        .clk      ( clock          ),
        .rst      ( reset          ),
        .number   ( 32' (distance) ),
        .dots     ( '0             ),
        .abcdefgh ( abcdefgh       ),
        .digit    ( digit          )
    );

    // Exercise: Use ultrasonic sensor to draw something on the screen

    // START_SOLUTION

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        if (x > distance [15:6])
            red = 31;
    end

    // END_SOLUTION

endmodule
