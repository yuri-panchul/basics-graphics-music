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

    localparam width = 4, depth = 4;

    wire               a_valid;
    wire               a_ready;
    wire [width - 1:0] a_data;

    wire               b_valid;
    wire               b_ready;
    wire [width - 1:0] b_data;

    wire               sum_valid;
    wire               sum_ready;
    wire [width - 1:0] sum_data;

    //------------------------------------------------------------------------

    generate
        if (w_key >= 3)
        begin : three_keys
            // For example Saulinx board

            assign a_valid   =   key [2];
            assign b_valid   =   key [1];
            assign sum_ready = ~ key [0];  // is not pressed - ready is ON by default
        end
        else if (w_key >= 2 && w_sw > 0)
        begin : two_keys_and_switch
            // For example DE0-Lite board

            assign a_valid   =   key [0];  // Top key is pressed
            assign b_valid   =   key [1];  // Bottom key is pressed
            assign sum_ready = ~ sw  [0];  // Switch is not ON
        end
        else
        begin : single_key
            assign a_valid   =   key [0];
            assign b_valid   =   key [0];
            assign sum_ready = ~ key [0];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef __ICARUS__

        logic [width - 1:0] data_const_array [0:2 ** width - 1];

        assign data_const_array [ 0] = 4'h2;
        assign data_const_array [ 1] = 4'h6;
        assign data_const_array [ 2] = 4'hd;
        assign data_const_array [ 3] = 4'hb;
        assign data_const_array [ 4] = 4'h7;
        assign data_const_array [ 5] = 4'he;
        assign data_const_array [ 6] = 4'hc;
        assign data_const_array [ 7] = 4'h4;
        assign data_const_array [ 8] = 4'h1;
        assign data_const_array [ 9] = 4'h0;
        assign data_const_array [10] = 4'h9;
        assign data_const_array [11] = 4'ha;
        assign data_const_array [12] = 4'hf;
        assign data_const_array [13] = 4'h5;
        assign data_const_array [14] = 4'h8;
        assign data_const_array [15] = 4'h3;

    `else

        // New SystemVerilog syntax for array assignment

        wire [width - 1:0] data_const_array [0:2 ** width - 1]
            = '{ 4'h2, 4'h6, 4'hd, 4'hb, 4'h7, 4'he, 4'hc, 4'h4,
                 4'h1, 4'h0, 4'h9, 4'ha, 4'hf, 4'h5, 4'h8, 4'h3 };

    `endif

    //------------------------------------------------------------------------

    wire [width - 1:0] a_data_index;

    counter_with_enable # (width) i_a_counter
    (
        .clk    (slow_clk),
        .enable (a_valid & a_ready),
        .cnt    (a_data_index),
        .*
    );

    assign a_data = data_const_array [a_data_index];

    //------------------------------------------------------------------------

    wire [width - 1:0] b_data_index;

    counter_with_enable # (width) i_b_counter
    (
        .clk    (slow_clk),
        .enable (b_valid & b_ready),
        .cnt    (b_data_index),
        .*
    );

    assign b_data = data_const_array [b_data_index + 1];

    //------------------------------------------------------------------------

    a_plus_b_using_wrapped_fifos
    # (.width (width), .depth (depth))
    a_plus_b (.clk (slow_clk), .*);

    //------------------------------------------------------------------------

    localparam w_number = w_digit * 4;

    wire [7:0] abcdefgh_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      (clk),
        .number   (w_number' ({ a_data, b_data, 4'd0, sum_data })),
        .dots     ('0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    //------------------------------------------------------------------------

    localparam sign_ready_a   = 8'b10000000,
               sign_ready_b   = 8'b00000010,
               sign_ready_sum = 8'b00010000,
               sign_nothing   = 8'b00000000;

    always_comb
        case (digit [3:0])
        4'b0001: abcdefgh = sum_valid ? abcdefgh_pre : sign_nothing;

        4'b0010:
        begin
            abcdefgh = sign_nothing;

            if ( a_ready   ) abcdefgh |= sign_ready_a;
            if ( b_ready   ) abcdefgh |= sign_ready_b;
            if ( sum_ready ) abcdefgh |= sign_ready_sum;
        end

        4'b0100,
        4'b1000: abcdefgh = abcdefgh_pre;

        default: abcdefgh = sign_nothing;
        endcase

endmodule

`endif
