module full_adder_testbench;

    timeunit      1ns;
    timeprecision 1ps;

    logic a, b, carry_in, sum, carry_out;

    full_adder dut_instance (.*);

    logic [1:0] expected_2_bit_value;

    initial
    begin
        $dumpvars (0, dut_instance);

        repeat (100)
        begin
            a        = $urandom ();
            b        = $urandom ();
            carry_in = $urandom ();

            expected_2_bit_value = a + b + carry_in;

            # 1

            $display ("%d a=%b b=%b carry_in=%b sum=%b carry_out=%b",
                $time, a, b, carry_in, sum, carry_out);

            if ({ carry_out, sum } !== expected_2_bit_value)
            begin
                $display ("ERROR: { carry_out, sum } is expected to be %b",
                    expected_2_bit_value);

                $finish;
            end
        end

        $finish;
    end

endmodule
