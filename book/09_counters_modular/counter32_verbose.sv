module counter32_verbose
(
    input         clk,
    input         rst,
    output [31:0] cnt
);

    logic [31:0] cnt_d, cnt_q;

    always_comb
        cnt_d = cnt_q + 1'd1;

    always_ff @ (posedge clk)
        if (rst)
            cnt_q <= '0;
        else
            cnt_q <= cnt_d;

    assign cnt = cnt_q;

endmodule
