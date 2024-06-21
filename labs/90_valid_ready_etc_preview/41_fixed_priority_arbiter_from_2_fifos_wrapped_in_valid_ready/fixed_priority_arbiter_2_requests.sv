`include "config.svh"

module fixed_priority_arbiter_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);

    assign grants = requests [0] ? 2'b01 : 2'b10;

endmodule
