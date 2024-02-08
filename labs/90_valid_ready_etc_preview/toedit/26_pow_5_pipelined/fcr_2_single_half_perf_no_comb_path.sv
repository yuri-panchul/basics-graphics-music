// This solution has no combinational path at all,
// but cannot sustain back-to-back stream of data.
//
// If you need full performance, use either:
//
// 1. Flow control register with combinational path.
// Disadvantage: problem with timing in long pipelines.
//
// 2. FIFO of depth 2 (or any other FIFO).
// Disadvantage: area and power consumption.
//
// 3. A so-called skid buffer (or double buffer),
// an equivalent of a two-deep FIFO.
// Disadvantage: area and power consumption.

// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module fcr_2_single_half_perf_no_comb_path
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

    always_ff @ (posedge clk)
        if (up_rdy)
            down_data <= up_data;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            down_vld <= 1'b0;
        else if (up_rdy)
            down_vld <= up_vld;
        else if (down_rdy)
            down_vld <= '0;

    assign up_rdy = ~ down_vld;

endmodule
