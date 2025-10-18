module counter32_brief
(
    input               clk,
    input               rst,
    output logic [31:0] cnt
);

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

endmodule
