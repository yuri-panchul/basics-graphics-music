`include "config.svh"

module round_robin_arbiter_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);

    logic last_grant_0;

    assign grants =   requests != 2'b11 ? requests
                    : last_grant_0      ? 2'b10
                    :                     2'b01;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            last_grant_0 <= '0;
        else
            case (requests)
            2'b00: ;
            2'b01: last_grant_0 <= 1'b1;
            2'b10: last_grant_0 <= 1'b0;
            2'b11: last_grant_0 <= ~ last_grant_0;
            endcase

endmodule
