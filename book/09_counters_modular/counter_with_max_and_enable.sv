module counter_with_max_and_enable
# (
    parameter max   = 0,
              width = $clog2 (max + 1)
)
(
    input                      clk,
    input                      rst,
    input                      enable,
    output logic [width - 1:0] cnt
);

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (enable)
            cnt <= (cnt == '0 ? width' (max) : cnt - 1'd1);

endmodule
