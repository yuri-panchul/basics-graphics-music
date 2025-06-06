`include "config.svh"

// Rotary Encoder Ky-040

module rotary_encoder
(
    input               clk,
    input               reset,
    input               a,
    input               b,
    output logic [15:0] value
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
            value <= - 16'd1;  // To do: figure out why we have to start with -1 and not 0
        end
        else if (a && ! prev_a)
        begin
            if (b)
                value <= value + 16'd1;
            else
                value <= value - 16'd1;
        end

endmodule
