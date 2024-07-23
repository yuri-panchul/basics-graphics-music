// A general-purpose flow-controlled register
// which allows full back-to-back performance
// but has combinational path between down_rdy and up_rdy
// which can introduce timing problems in deep pipelines.

// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module fcr_1_single_allows_back_to_back
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

    assign up_rdy = ~ down_vld | down_rdy;

endmodule
