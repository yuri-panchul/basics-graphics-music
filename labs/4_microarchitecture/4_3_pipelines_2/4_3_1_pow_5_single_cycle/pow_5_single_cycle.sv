// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

   `define FCR fcr_1_single_allows_back_to_back
// `define FCR fcr_2_single_half_perf_no_comb_path
// `define FCR fcr_3_single_for_pipes_with_global_stall
// `define FCR fcr_4_wrapped_2_deep_fifo
// `define FCR fcr_5_double_buffer_from_dally_harting

module pow_5_single_cycle
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

    wire int_vld, int_rdy;  // Internal vld and rdy
    wire [width - 1:0] arg;

    `FCR # (.w (width)) in_reg
    (
        .up_vld    ( up_vld  ),
        .up_rdy    ( up_rdy  ),
        .up_data   ( up_data ),

        .down_vld  ( int_vld ),
        .down_rdy  ( int_rdy ),
        .down_data ( arg     ),

        .*
    );

    wire [width - 1:0] res = arg * arg * arg * arg * arg;

    `FCR # (.w (width)) out_reg
    (
        .up_vld    ( int_vld   ),
        .up_rdy    ( int_rdy   ),
        .up_data   ( res       ),

        .down_vld  ( down_vld  ),
        .down_rdy  ( down_rdy  ),
        .down_data ( down_data ),

        .*
    );

endmodule

`undef FCR
