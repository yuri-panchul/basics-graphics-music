module counter_and_strobe_generator
# (
    parameter clk_mhz = 50
)
(
    input               clk,
    input               rst,
    output logic [15:0] cnt
);

    logic enable;

    strobe_gen # (.clk_mhz (clk_mhz), .strobe_hz (5))
    i_strobe_gen (clk, rst, enable);

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (enable)
            cnt <= cnt + 1'd1;

endmodule
