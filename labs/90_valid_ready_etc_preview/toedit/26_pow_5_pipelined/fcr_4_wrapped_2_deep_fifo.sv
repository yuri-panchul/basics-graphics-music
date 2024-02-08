// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module fcr_4_wrapped_2_deep_fifo
# (
    parameter w = 0
)
(
    input                  clk,
    input                  rst,

    input                  up_vld,
    output                 up_rdy,
    input        [w - 1:0] up_data,

    output logic           down_vld,
    input                  down_rdy,
    output logic [w - 1:0] down_data
);

    wire fifo_push;
    wire fifo_pop;
    wire fifo_empty;
    wire fifo_full;

    assign up_rdy    = ~ fifo_full;
    assign fifo_push = up_vld & up_rdy;

    assign down_vld  = ~ fifo_empty;
    assign fifo_pop  = down_vld & down_rdy;

    ff_fifo_pow2_depth
    # (.width (w), .depth (2))
    fifo
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .push       ( fifo_push  ),
        .pop        ( fifo_pop   ),
        .write_data ( up_data    ),
        .read_data  ( down_data  ),
        .empty      ( fifo_empty ),
        .full       ( fifo_full  )
    );

endmodule
