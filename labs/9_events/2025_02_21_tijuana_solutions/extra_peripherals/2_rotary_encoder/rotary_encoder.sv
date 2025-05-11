`include "config.svh"

module rotary_encoder
(
    input               clk,
    input               reset,
    input               a,
    input               b,
    output logic [15:0] value,
    input               sw,
    output logic        sw_state
);

    logic prev_a;

    always_ff @ (posedge clk)
        if (reset)
            prev_a <= 1'b1;
        else
            prev_a <= a;

    always_ff @ (posedge clk)
        if (reset)
        begin
            value <= - 16'd1;
        end
        else if (a && ! prev_a)
        begin
            if (b)
                value <= value + 16'd1;
            else
                value <= value - 16'd1;
        end

    // Simple switch handling with optional inversion
    // Try both options to see which works with your hardware
    // Option 1: Direct assignment
    assign sw_state = sw;
    
    // Option 2: Inverted (if switch is active-low)
    // assign sw_state = !sw;

endmodule