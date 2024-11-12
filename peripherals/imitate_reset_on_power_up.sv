`include "config.svh"

module imitate_reset_on_power_up
(
    input  clk,
    output rst
);

    /*
    // Note that flop initialization works only in FPGA and not ASIC

    logic [25:0] rst_cnt = '1;
    assign rst = | rst_cnt;

    always_ff @ (posedge clk)
        if (rst)
            rst_cnt <= rst_cnt - 1'b1;

    */

    // Alternative implementation - not suitable for CDC or slow clock

    logic  rst_r = 1'b1;
    assign rst   = rst_r;

    always_ff @ (posedge clk)
        rst_r <= 1'b0;

endmodule
