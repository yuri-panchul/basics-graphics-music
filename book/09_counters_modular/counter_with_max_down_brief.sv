module counter_with_max_down_brief
# (
    parameter max   = 0,
              width = $clog2 (max)
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
            cnt <= (cnt == '0 ? width' (max) : cnt - 1'd1);

endmodule
