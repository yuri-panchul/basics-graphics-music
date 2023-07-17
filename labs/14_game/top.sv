`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 20,

              strobe_to_update_xy_counter_width = 20
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,

    // General-purpose Input/Output

    inout  logic [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

       assign led      = '0;
       assign abcdefgh = '0;
       assign digit    = '0;
    // assign vsync    = '0;
    // assign hsync    = '0;
    // assign red      = '0;
    // assign green    = '0;
    // assign blue     = '0;

    //------------------------------------------------------------------------

    wire [2:0] rgb;

    game_top
    # (
        .clk_mhz (clk_mhz),

        .strobe_to_update_xy_counter_width
        (strobe_to_update_xy_counter_width)
    )
    i_game_top
    (
        .clk              (   clk                ),
        .rst              (   rst                ),

        .launch_key       ( | key                ),
        .left_right_keys  ( { key [1], key [0] } ),

        .hsync            (   hsync              ),
        .vsync            (   vsync              ),
        .rgb              (   rgb                )
    );

    assign red   = { 4 { rgb [2] } };
    assign green = { 4 { rgb [1] } };
    assign blue  = { 4 { rgb [0] } };

endmodule
