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

    //------------------------------------------------------------------------

    // assign led      = '0;
    // assign abcdefgh = '0;
    // assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;
       assign sound    = '0;

    //------------------------------------------------------------------------

    localparam width = 4, depth = w_digit;

    // Upstream

    wire               up_valid   = key [1];
    wire               up_ready;
    wire [width - 1:0] up_data;

    // Downstream

    wire               down_valid;
    wire               down_ready = key [0];
    wire [width - 1:0] down_data;

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
        .enable (up_valid & up_ready),
        .cnt    (up_data_index),
        .*
    );

    assign up_data = up_data_const_array [up_data_index];

    //------------------------------------------------------------------------

    ff_fifo_wrapped_in_valid_ready
    # (.width (width), .depth (depth))
    wrapped_fifo (.clk (slow_clk), .*);

    //------------------------------------------------------------------------

    localparam w_number = w_digit * 4;

    wire [7:0] abcdefgh_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      (clk),
        .number   (w_number' ({ up_data, 4'd0, 4'd0, down_data })),
        .dots     ('0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    //------------------------------------------------------------------------

    localparam sign_valid   = 8'b10000000,
               sign_ready   = 8'b00000010,
               sign_nothing = 8'b00000000;

    function [7:0] valid_ready_to_abcdefgh (logic valid, ready);

        case ({ valid, ready })
        2'b00: return sign_nothing;
        2'b10: return sign_valid;
        2'b01: return sign_ready;
        2'b11: return sign_valid | sign_ready;
        endcase

    endfunction

    //------------------------------------------------------------------------

    always_comb
        case (digit [3:0])
        4'b0100:  abcdefgh = valid_ready_to_abcdefgh ( up_valid   , up_ready   );
        4'b0010:  abcdefgh = valid_ready_to_abcdefgh ( down_valid , down_ready );
        4'b0001:  abcdefgh = down_valid ? abcdefgh_pre : sign_nothing;
        4'b1000:  abcdefgh = abcdefgh_pre;
        default:  abcdefgh = sign_nothing;
        endcase

endmodule

`endif
