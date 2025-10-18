module counter_enables_counter
(
    input               clk,
    input               rst,
    output logic [15:0] cnt
);

    logic [19:0] cnt_e;

    always_ff @ (posedge clk)
        if (rst)
            cnt_e <= '0;
        else
            cnt_e <= cnt_e + 1'd1;

    wire enable = (cnt_e == '0);

    // 2 ** 20 = (2 ** 10) * (2 ** 10) = 1024 * 1024 = approximate 1000000.
    // For 27 MHz clock:
    // 27 MHz 27000000 / 2 ** 20 = 27 times a cnt_e overflows.

    always_ff @ (posedge clk)
        if (rst)
            cnt <= '0;
        else if (enable)
            cnt <= cnt + 1'd1;

endmodule
