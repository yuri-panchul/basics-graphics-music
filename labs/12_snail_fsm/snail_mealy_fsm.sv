// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"

module snail_mealy_fsm
(
    input  clk,
    input  rst,
    input  en,
    input  a,
    output y
);

    typedef enum bit
    {
        S0 = 1'd0,
        S1 = 1'd1
    }
    state_e;

    state_e state, next_state;

    // State register

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            state <= S0;
        else if (en)
            state <= next_state;

    // Next state logic

    always_comb
    begin
        next_state = state;

        case (state)
        S0: if (~ a) next_state = S1;
        S1: if (  a) next_state = S0;
        endcase
    end

    // Output logic based on current state and inputs

    assign y = (a & state == S1);

endmodule
