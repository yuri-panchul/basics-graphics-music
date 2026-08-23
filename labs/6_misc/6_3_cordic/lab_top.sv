`include "config.svh"

`ifndef SIMULATION

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
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

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    logic              start;
    logic       [15:0] angle;

    wire               calc;
    wire               finish;

    wire signed [15:0] cos_out;
    wire signed [15:0] sin_out;

    cordic i_cordic (.*);
    (
        .clk     ( slow_clk ),
        .rst,

        .start   ( key [0]  ),
        .angle,

        .calc    ( led [1]  ),
        .finish  ( led [0]  ),

        .cos_out,
        .sin_out
    );

    //------------------------------------------------------------------------

    `ifdef __ICARUS__

        localparam angle_array_index_width = 4,
                   angle_array_length      = 1 << angle_array_index_width;

        logic [15:0] angle_const_array [0:angle_array_length - 1];

        assign angle_const_array [ 0] = 4'h0002;
        assign angle_const_array [ 1] = 4'h0006;
        assign angle_const_array [ 2] = 4'h000d;
        assign angle_const_array [ 3] = 4'h000b;
        assign angle_const_array [ 4] = 4'h0007;
        assign angle_const_array [ 5] = 4'h000e;
        assign angle_const_array [ 6] = 4'h000c;
        assign angle_const_array [ 7] = 4'h0004;
        assign angle_const_array [ 8] = 4'h0001;
        assign angle_const_array [ 9] = 4'h0000;
        assign angle_const_array [10] = 4'h0009;
        assign angle_const_array [11] = 4'h000a;
        assign angle_const_array [12] = 4'h000f;
        assign angle_const_array [13] = 4'h0005;
        assign angle_const_array [14] = 4'h0008;
        assign angle_const_array [15] = 4'h0003;

    `else

        // New SystemVerilog syntax for array assignment

        wire [15:0] angle_const_array [0:angle_array_length - 1] =
        '{
            4'h0002, 4'h0006, 4'h000d, 4'h000b,
            4'h0007, 4'h000e, 4'h000c, 4'h0004,
            4'h0001, 4'h0000, 4'h0009, 4'h000a,
            4'h000f, 4'h0005, 4'h0008, 4'h0003
        };

    `endif

    //------------------------------------------------------------------------

    wire [width - 1:0] angle_index;

    counter_with_enable # (width) i_counter
    (
        .clk    (slow_clk),
        .rst,
        .enable (start),
        .cnt    (angle_index)
    );

    assign angle = angle_const_array [angle_index];

    //------------------------------------------------------------------------

    logic [15:0] angle_sticky;
    logic [15:0] sin_out_sticky;

    always_ff @ (posedge clk)
        if (rst)
        begin
            angle_sticky   <= '0;
            sin_out_sticky <= '0;
        end
        else
        begin
            if (start)
                angle_sticky <= angle;

             if (calc | finish)
                sin_out_sticky <= sin_out;
        end

    seven_segment_display # (w_digit) i_display
    (
        .clk,
        .rst,
        .number ({ angle_sticky, sin_out_sticky }),
        .dots ('0),
        .abcdefgh,
        .digit
    );

endmodule

`endif
