// Board configuration: tang_nano_9k_lcd_800_480_tm1638_hackathon
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

    input  logic [9:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);

    wire a, b;

    sync_and_debounce # (.w (2))
    i_sync_and_debounce
    (
        .clk      ( clock       ),
        .reset    ( reset       ),
        .sw_in    ( gpio [3:2]  ),
        .sw_out   ( { b, a }    )
    );

    wire [15:0] value;

    rotary_encoder i_rotary_encoder
    (
        .clk      ( clock       ),
        .reset    ( reset       ),
        .a        ( a           ),
        .b        ( b           ),
        .value    ( value       )
    );

    seven_segment_display
    # (.w_digit (8))
    i_7segment
    (
        .clk      ( clock       ),
        .rst      ( reset       ),
        .number   ( 32' (value) ),
        .dots     ( '0          ),
        .abcdefgh ( abcdefgh    ),
        .digit    ( digit       )
    );

    // Exercise 1: Use ultrasonic sensor to draw something on the screen

    // Exercise 2: Connect two ultrasonic sensors
    // to draw something on the screen

endmodule
