module d_flip_flop
(
    input  clk,
    input  d,
    output logic q
);

    always_ff @ (posedge clk)
        q <= d;

endmodule
