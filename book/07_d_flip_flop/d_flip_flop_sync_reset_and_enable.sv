module d_flip_flop_sync_rst_and_enable
(
    input  clk,
    input  rst,
    input  enable,
    input  d,
    output logic q
);

    always_ff @ (posedge clk)
        if (rst)
            q <= 1'b0;
        else if (enable)
            q <= d;

endmodule
