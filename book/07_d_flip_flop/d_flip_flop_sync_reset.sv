module d_flip_flop_sync_rst
(
    input  clk,
    input  rst,
    input  d,
    output logic q
);

    always_ff @ (posedge clk)
        if (rst)
            q <= 1'b0;
        else
            q <= d;

endmodule
