// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

// This solution is a Yuri Panchul's edition
// of the code derived from:
//
// Digital Design: A Systems Approach
// by William James Dally and R. Curtis Harting
// 2012

// It is equivalent to 2-deep FIFO

module fcr_5_double_buffer_from_dally_harting
# (
    parameter w = 0
)
(
    input                  clk,
    input                  rst,

    input                  up_vld,
    output logic           up_rdy,
    input        [w - 1:0] up_data,

    output logic           down_vld,
    input                  down_rdy,
    output logic [w - 1:0] down_data
);

    logic           buf_vld;
    logic [w - 1:0] buf_data;

    always_ff @ (posedge clk)
    begin
        if (up_rdy & ~ down_rdy)
            buf_data <= up_data;

        if (down_rdy)
            down_data <= up_rdy ? up_data : buf_data;
    end

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            buf_vld  <= 1'b0;
            down_vld <= 1'b0;
            up_rdy   <= 1'b1;
        end
        else
        begin
            if (up_rdy & ~ down_rdy)
                buf_vld  <= up_vld;

            if (down_rdy)
                down_vld <= up_rdy ? up_vld : buf_vld;

            up_rdy <= down_rdy;
        end

endmodule
