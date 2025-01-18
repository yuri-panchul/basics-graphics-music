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

    localparam width = 4;

    // Upstream

    wire                   up_vld = key [1];
    wire                   up_rdy;
    wire [2 * width - 1:0] up_data;
    // Downstream

    wire                   down_vld;
    wire                   down_rdy = ~ key [0]; // Ready is ON by default
    wire [    width - 1:0] down_data;

    //------------------------------------------------------------------------

    `ifdef __ICARUS__

        logic [width - 1:0] up_data_const_array [0:2 ** width - 1];

        assign up_data_const_array [ 0] = 4'h2;
        assign up_data_const_array [ 1] = 4'h6;
        assign up_data_const_array [ 2] = 4'hd;
        assign up_data_const_array [ 3] = 4'hb;
        assign up_data_const_array [ 4] = 4'h7;
        assign up_data_const_array [ 5] = 4'he;
        assign up_data_const_array [ 6] = 4'hc;
        assign up_data_const_array [ 7] = 4'h4;
        assign up_data_const_array [ 8] = 4'h1;
        assign up_data_const_array [ 9] = 4'h0;
        assign up_data_const_array [10] = 4'h9;
        assign up_data_const_array [11] = 4'ha;
        assign up_data_const_array [12] = 4'hf;
        assign up_data_const_array [13] = 4'h5;
        assign up_data_const_array [14] = 4'h8;
        assign up_data_const_array [15] = 4'h3;

    `else

        // New SystemVerilog syntax for array assignment

        wire [width - 1:0] up_data_const_array [0:2 ** width - 1]
            = '{ 4'h2, 4'h6, 4'hd, 4'hb, 4'h7, 4'he, 4'hc, 4'h4,
                 4'h1, 4'h0, 4'h9, 4'ha, 4'hf, 4'h5, 4'h8, 4'h3 };

    `endif

    //------------------------------------------------------------------------

    wire [width - 1:0] up_data_index;

    counter_with_enable # (width) i_counter
    (
        .clk    (slow_clk),
        .enable (up_vld & up_rdy),
        .cnt    (up_data_index),
        .*
    );

    assign up_data
        = { up_data_const_array [up_data_index    ],
            up_data_const_array [up_data_index ^ 2]  };

    //------------------------------------------------------------------------

    gearbox_2_to_1 # ( .width (width) )
    i_gearbox21 ( .clk (slow_clk), .* );

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh_pre;
    wire [w_digit - 1:0] digit_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      (clk),
        .number   ({ up_data, 4'b0, down_data }),
        .dots     ({ { 2 { up_vld } }, 2'b0 }),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit_pre),
        .*
    );

    //------------------------------------------------------------------------

    localparam sign_nothing = 8'b0000_0000;

    always_comb
        if (    digit [1]
            | ( digit [0] & ~ down_vld ))
            abcdefgh = sign_nothing;
        else
            abcdefgh = abcdefgh_pre;

    assign digit = w_digit' (digit_pre & 4'b1111);

    assign led = w_led' ({ slow_clk, up_vld, up_rdy, down_vld, down_rdy });

endmodule

`endif
