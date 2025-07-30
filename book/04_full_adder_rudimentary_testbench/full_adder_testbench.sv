module full_adder_testbench;

    logic a, b, carry_in, sum, carry_out;

    full_adder dut_instance (.*);

    initial
    begin
        a        = 1'b0;
        b        = 1'b1;
        carry_in = 1'b1;

        # 1

        if (sum === 1'b0 & carry_out === 1'b1)
            $display ("PASS");
        else
            $display ("FAIL: Unexpected result: %b", { carry_out, sum });
    end

endmodule
