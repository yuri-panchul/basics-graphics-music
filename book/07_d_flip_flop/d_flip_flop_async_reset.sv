module d_flip_flop_async_rst
(
    input  clk,
    input  rst,
    input  d,
    output logic q
);

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            q <= 1'b0;
        else
            q <= d;

endmodule
