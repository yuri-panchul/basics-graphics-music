module counter_with_width
# (
    parameter width = 0
)
(
    input                      clk,
    input                      rst,
    output logic [width - 1:0] cnt
);

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

endmodule
