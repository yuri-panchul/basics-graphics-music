`include "config.svh"

module top
# (
    parameter clk_mhz   = 50,
              pixel_mhz = 25,
              w_key     = 4,
              w_sw      = 8,
              w_led     = 8,
              w_digit   = 8,
              w_gpio    = 100,
              w_red     = 4,
              w_green   = 4,
              w_blue    = 4
)
(
    input                        clk,
    input                        slow_clk,
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
    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,
    output logic                 dsp_on,
    output logic                 clk_px,

    input                        uart_rx,
    output                       uart_tx,

    input        [         23:0] mic,
    output       [         15:0] sound,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    localparam strobe_to_update_xy_counter_width
        = $clog2 (clk_mhz * 1000 * 1000) - 6;

    //------------------------------------------------------------------------

       assign led      = '0;
       assign abcdefgh = '0;
       assign digit    = '0;
    // assign vsync    = '0;
    // assign hsync    = '0;
    // assign red      = '0;
    // assign green    = '0;
    // assign blue     = '0;
       assign sound    = '0;
       assign uart_tx  = '1;

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
        .rgb              (   rgb                ),
        .dsp_on           (   dsp_on             ),
        .clk_px           (   clk_px             )
     
    );

    assign red   = { w_red   { rgb [2] } };
    assign green = { w_green { rgb [1] } };
    assign blue  = { w_blue  { rgb [0] } };

endmodule
