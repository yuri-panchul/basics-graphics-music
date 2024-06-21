// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

   `define FCR fcr_1_single_allows_back_to_back
// `define FCR fcr_2_single_half_perf_no_comb_path
// `define FCR fcr_3_single_for_pipes_with_global_stall
// `define FCR fcr_4_wrapped_2_deep_fifo
// `define FCR fcr_5_double_buffer_from_dally_harting

module pow_5_pipelined
# (
    parameter width = 0
)
(
    input                clk,
    input                rst,

    input                up_vld,    // upstream
    output               up_rdy,
    input  [width - 1:0] up_data,

    output               down_vld,  // downstream
    input                down_rdy,
    output [width - 1:0] down_data
);

    wire vld_1, rdy_1;
    wire [width - 1:0] arg_1;

    `FCR # (.w (width)) r0
    (
        .up_vld    ( up_vld  ),
        .up_rdy    ( up_rdy  ),
        .up_data   ( up_data ),

        .down_vld  ( vld_1   ),
        .down_rdy  ( rdy_1   ),
        .down_data ( arg_1   ),

        .*
    );

    wire [width - 1:0] mul_1_d = arg_1 * arg_1;

    wire vld_2, rdy_2;
    wire [width - 1:0] arg_2, mul_1_q;

    `FCR # (.w (2 * width)) r1
    (
        .up_vld    ( vld_1 ),
        .up_rdy    ( rdy_1 ),
        .up_data   ( { arg_1, mul_1_d } ),

        .down_vld  ( vld_2 ),
        .down_rdy  ( rdy_2 ),
        .down_data ( { arg_2, mul_1_q } ),

        .*
    );

    wire [width - 1:0] mul_2_d = arg_2 * mul_1_q;

    wire vld_3, rdy_3;
    wire [width - 1:0] arg_3, mul_2_q;

    `FCR # (.w (2 * width)) r2
    (
        .up_vld    ( vld_2 ),
        .up_rdy    ( rdy_2 ),
        .up_data   ( { arg_2, mul_2_d } ),

        .down_vld  ( vld_3 ),
        .down_rdy  ( rdy_3 ),
        .down_data ( { arg_3, mul_2_q } ),

        .*
    );

    wire [width - 1:0] mul_3_d = arg_3 * mul_2_q;

    wire vld_4, rdy_4;
    wire [width - 1:0] arg_4, mul_3_q;

    `FCR # (.w (2 * width)) r3
    (
        .up_vld    ( vld_3 ),
        .up_rdy    ( rdy_3 ),
        .up_data   ( { arg_3, mul_3_d } ),

        .down_vld  ( vld_4 ),
        .down_rdy  ( rdy_4 ),
        .down_data ( { arg_4, mul_3_q } ),

        .*
    );

    wire [width - 1:0] mul_4_d = arg_4 * mul_3_q;

    `FCR # (.w (width)) r4
    (
        .up_vld    ( vld_4     ),
        .up_rdy    ( rdy_4     ),
        .up_data   ( mul_4_d   ),

        .down_vld  ( down_vld  ),
        .down_rdy  ( down_rdy  ),
        .down_data ( down_data ),

        .*
    );

endmodule

`undef FCR
