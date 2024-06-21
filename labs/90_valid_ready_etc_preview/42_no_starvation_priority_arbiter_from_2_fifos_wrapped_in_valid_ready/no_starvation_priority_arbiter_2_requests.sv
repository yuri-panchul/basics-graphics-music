`include "config.svh"

module no_starvation_priority_arbiter_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);

    wire [7:0] requests_8 = { { 7 { requests [1] } }, requests [0] };
    wire [7:0] grants_8;

    assign grants = { | grants_8 [7:1], grants_8 [0] };

    round_robin_arbiter_8_reqs arbiter_8
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .ena   ( 1'b1       ),
        .req   ( requests_8 ),
        .gnt   ( grants_8   )
    );

endmodule
