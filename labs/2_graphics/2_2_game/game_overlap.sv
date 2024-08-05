`include "game_config.svh"

module game_overlap
(
    input                       clk,
    input                       rst,

    input      [`X_WIDTH - 1:0] left_1,
    input      [`X_WIDTH - 1:0] right_1,
    input      [`Y_WIDTH - 1:0] top_1,
    input      [`Y_WIDTH - 1:0] bottom_1,

    input      [`X_WIDTH - 1:0] left_2,
    input      [`X_WIDTH - 1:0] right_2,
    input      [`Y_WIDTH - 1:0] top_2,
    input      [`Y_WIDTH - 1:0] bottom_2,

    output logic                  overlap
);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            overlap <= 1'b0;
        else
            overlap <= ! (    right_1  < left_2
                           || right_2  < left_1
                           || bottom_1 < top_2
                           || bottom_2 < top_1  );

endmodule
