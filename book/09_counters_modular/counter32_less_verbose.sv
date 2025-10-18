module counter32_less_verbose
(
    input         clk,
    input         rst,
    output [31:0] cnt
);

    logic [31:0] cnt_r;

    always_ff @ (posedge clk)
        if (rst)
            cnt_r <= '0;
        else
            cnt_r <= cnt_r + 1'd1;

    assign cnt = cnt_r;

endmodule
