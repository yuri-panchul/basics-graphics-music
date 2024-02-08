// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module pow_5_pipelined_without_flow_control
# (
    parameter width = 0
)
(
    input                clk,
    input                rst,

    input                up_vld,
    input  [width - 1:0] up_data,

    output               down_vld,
    output [width - 1:0] down_data
);

    wire vld_1;
    wire [width - 1:0] arg_1;

    reg_without_flow_control # (.w (width)) r0
    (
        .up_vld    ( up_vld  ),
        .up_data   ( up_data ),

        .down_vld  ( vld_1   ),
        .down_data ( arg_1   ),

        .*
    );

    wire [width - 1:0] mul_1_d = arg_1 * arg_1;

    wire vld_2;
    wire [width - 1:0] arg_2, mul_1_q;

    reg_without_flow_control # (.w (2 * width)) r1
    (
        .up_vld    ( vld_1 ),
        .up_data   ( { arg_1, mul_1_d } ),

        .down_vld  ( vld_2 ),
        .down_data ( { arg_2, mul_1_q } ),

        .*
    );

    wire [width - 1:0] mul_2_d = arg_2 * mul_1_q;

    wire vld_3;
    wire [width - 1:0] arg_3, mul_2_q;

    reg_without_flow_control # (.w (2 * width)) r2
    (
        .up_vld    ( vld_2 ),
        .up_data   ( { arg_2, mul_2_d } ),

        .down_vld  ( vld_3 ),
        .down_data ( { arg_3, mul_2_q } ),

        .*
    );

    wire [width - 1:0] mul_3_d = arg_3 * mul_2_q;

    wire vld_4;
    wire [width - 1:0] arg_4, mul_3_q;

    reg_without_flow_control # (.w (2 * width)) r3
    (
        .up_vld    ( vld_3 ),
        .up_data   ( { arg_3, mul_3_d } ),

        .down_vld  ( vld_4 ),
        .down_data ( { arg_4, mul_3_q } ),

        .*
    );

    wire [width - 1:0] mul_4_d = arg_4 * mul_3_q;

    reg_without_flow_control # (.w (width)) r4
    (
        .up_vld    ( vld_4     ),
        .up_data   ( mul_4_d   ),

        .down_vld  ( down_vld  ),
        .down_data ( down_data ),

        .*
    );

endmodule
