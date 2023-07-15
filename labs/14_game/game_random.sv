`include "game_config.svh"

module game_random
(
    input             clk,
    input             rst,
    output logic [15:0] random
);

    // Uses LFSR, Linear Feedback Shift Register

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            random <= 16'b1111111111111;
        else
            random <=   { random [14:0], 1'b0 }
                      ^ ( random [15] ? 16'b1000000001011 : 16'b0);

endmodule
