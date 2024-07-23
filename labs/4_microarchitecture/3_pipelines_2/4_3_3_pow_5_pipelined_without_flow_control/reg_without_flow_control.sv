`include "config.svh"

module reg_without_flow_control
# (
    parameter w = 0
)
(
    input                  clk,
    input                  rst,

    input                  up_vld,
    input        [w - 1:0] up_data,

    output logic           down_vld,
    output logic [w - 1:0] down_data
);

    // "if (up_vld)" helps to reduce switching
    // and save dynamic power since synthesis
    // converts it into clock enable

    always_ff @ (posedge clk)
        if (up_vld)
            down_data <= up_data;

    // Valid bit, unlike data bit, has to have a reset

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            down_vld <= 1'b0;
        else
            down_vld <= up_vld;

endmodule
