// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module pow_5_pipelined_with_credit_counter
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

    localparam pipeline_depth = 5;

    //--------------------------------------------------------------------------
    // Pipeline without flow control - everything falls through

    wire               pipe_up_vld;
    wire [width - 1:0] pipe_up_data;

    wire               pipe_down_vld;
    wire [width - 1:0] pipe_down_data;

    pow_5_pipelined_without_flow_control
    # (.width (width))
    pipe
    (
        .up_vld    ( pipe_up_vld    ),
        .up_data   ( pipe_up_data   ),

        .down_vld  ( pipe_down_vld  ),
        .down_data ( pipe_down_data ),

        .*
    );

    //--------------------------------------------------------------------------
    // Output FIFO

    wire               fifo_push;
    wire               fifo_pop;
    wire [width - 1:0] fifo_write_data;
    wire [width - 1:0] fifo_read_data;
    wire               fifo_empty;
    wire               fifo_full;

    flip_flop_fifo_with_counter
    # (.width (width), .depth (pipeline_depth))
    fifo
    (
        .push       ( fifo_push       ),
        .pop        ( fifo_pop        ),
        .write_data ( fifo_write_data ),
        .read_data  ( fifo_read_data  ),
        .empty      ( fifo_empty      ),
        .full       ( fifo_full       ),
        .*
    );

    //--------------------------------------------------------------------------
    // Credit counter

    localparam crd_cnt_width = $clog2 (pipeline_depth + 1);

    logic [crd_cnt_width - 1:0] crd_cnt, new_crd_cnt;

    always_comb
    begin
        new_crd_cnt = crd_cnt;

        case ({ pipe_up_vld, fifo_pop })
        2'b10: new_crd_cnt --;
        2'b01: new_crd_cnt ++;
        endcase
    end

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            crd_cnt <= crd_cnt_width' (pipeline_depth);
        else
            crd_cnt <= new_crd_cnt;

    //--------------------------------------------------------------------------
    // Valid logic

    assign up_rdy          =   crd_cnt != '0 | fifo_pop;

    assign pipe_up_vld     =   up_vld & up_rdy;
    assign pipe_up_data    =   up_data;

    assign fifo_push       =   pipe_down_vld;
    assign fifo_pop        =   down_vld & down_rdy;
    assign fifo_write_data =   pipe_down_data;

    assign down_vld        = ~ fifo_empty;
    assign down_data       =   fifo_read_data;

endmodule
