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

    logic [31:0] counter;

    always_ff @ (posedge clock)
        if (reset)
            counter <= 0;
        else
            counter <= counter + 1;

    wire enable = (counter [22:0] == 0);
    // Try different slices here, for example "counter [20:0] == 0"

    // Alternatively you can instantiate strobe generator:

    /*

    wire enable;
    strobe_gen # (.clk_mhz (27), .strobe_hz (10))
    i_strobe_gen (.clk (clock), .rst (reset), .strobe (enable));

    */

    //------------------------------------------------------------------------

    wire button_on = | key;

    logic [7:0] shift_reg;

    always_ff @ (posedge clock)
        if (reset)
            shift_reg <= 8'b11111111;
        else if (enable)
            shift_reg <= { button_on, shift_reg [7:1] };
            // Alternatively you can write:
            // shift_reg <= (button_on << 7) | (shift_reg >> 1);

    assign led = shift_reg;

    // Exercise 1: Make the light move in the opposite direction.


    // Exercise 2: Make the light moving in a loop.
    // Use another key to reset the moving lights back to no lights.


    // Exercise 3: Display the state of the shift register
    // on a seven-segment display, moving the light in a circle.


endmodule
