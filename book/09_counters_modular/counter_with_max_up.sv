module counter_with_max_up
# (
    parameter max   = 0,
              width = $clog2 (max + 1)
)
(
    input                      clk,
    input                      rst,
    output logic [width - 1:0] cnt
);

    // It is not recommended to put "if (rst | cnt == max)"
    // because some lint programs do not like it

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (cnt == max)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

endmodule
