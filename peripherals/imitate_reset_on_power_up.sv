`include "config.svh"

module imitate_reset_on_power_up
(
    input  clk,
    output rst
);

    logic [24:0] rst_cnt = '1;
    assign rst = | rst_cnt;

    always_ff @ (posedge clk)
        if (rst)
            rst_cnt <= rst_cnt - 1'b1;

endmodule
