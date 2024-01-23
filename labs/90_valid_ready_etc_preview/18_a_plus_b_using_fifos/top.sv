// Asynchronous reset here is needed for the FPGA board we use

`include "config.svh"

`ifndef SIMULATION

module top
# (
        parameter clk_mhz = 50,
                            w_key   = 4,
                            w_sw    = 8,
                            w_led   = 8,
                            w_digit = 8,
                            w_gpio  = 20
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
        output logic [          3:0] red,
        output logic [          3:0] green,
        output logic [          3:0] blue,

        input                        uart_rx,
        output                       uart_tx,

        input                        mic_ready,
        input        [         23:0] mic,
        output       [         15:0] sound,

        // General-purpose Input/Output

        inout        [w_gpio  - 1:0] gpio
);

        //--------------------------------------------------------------------

        // assign led      = '0;
        // assign abcdefgh = '0;
        // assign digit    = '0;
              assign vsync    = '0;
              assign hsync    = '0;
              assign red      = '0;
              assign green    = '0;
              assign blue     = '0;
              assign sound    = '0;

        //--------------------------------------------------------------------

    //------------------------------------------------------------------------

    wire rst = ~ reset_n;

    assign led    = '1;
    assign buzzer = 1'b1;
    assign hsync  = 1'b1;
    assign vsync  = 1'b1;
    assign rgb    = 3'b0;

    //------------------------------------------------------------------------

    wire               a_valid   = key [2];
    wire               a_ready;
    wire [width - 1:0] a_data;

    wire               b_valid   = key [1];
    wire               b_ready;
    wire [width - 1:0] b_data;

    // key [0] is not pressed - ready is ON by default

    wire               sum_valid;
    wire               sum_ready = ~ key [0];
    wire [width - 1:0] sum_data;

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

    a_plus_b_using_fifos
    # (.width (width), .depth (depth))
    a_plus_b (.clk (slow_clk), .*);

    //------------------------------------------------------------------------

    wire [7:0] abcdefgh_pre;

    seven_segment_4_digits i_display
    (
        .clk      (clk),
        .number   ({ a_data, b_data, 4'd0, sum_data }),
        .dots     (4'b0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    //------------------------------------------------------------------------

    localparam sign_ready_a   = 8'b01111111,
               sign_ready_b   = 8'b11111101,
               sign_ready_sum = 8'b11101111,
               sign_nothing   = 8'b11111111;

    always_comb
        case (digit)
        4'b1110: abcdefgh = sum_valid ? abcdefgh_pre : sign_nothing;

        4'b1101:
        begin
            abcdefgh = sign_nothing;

            if ( a_ready   ) abcdefgh &= sign_ready_a;
            if ( b_ready   ) abcdefgh &= sign_ready_b;
            if ( sum_ready ) abcdefgh &= sign_ready_sum;
        end

        default: abcdefgh = abcdefgh_pre;
        endcase

endmodule
