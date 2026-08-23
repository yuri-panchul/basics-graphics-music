    // 10 ns clock period
    always #5 clk = ~clk;

    initial begin

        clk   = 0;
        rst   = 1;
        start = 0;
        angle = 0;

        // Hold reset for two clock cycles
        #20;

        rst = 0;

        #10;


        // ------------------------------------------------
        // TEST: 30 degrees
        //
        // angle encoding:
        //
        // 30 / 360 * 65536
        // = 5461
        // = 0x1555
        //
        // expected:
        //
        // sin(30) = 0.5
        // Q1.15 ≈ 16384
        //
        // cos(30) ≈ 0.866025
        // Q1.15 ≈ 28378
        // ------------------------------------------------

        angle = 16'h1555;

        start = 1;

        #10;

        start = 0;


        // Wait until CORDIC says calculation is done
        wait(finish == 1'b1);


        $display("----------------------------");
        $display("CORDIC RESULT");
        $display("angle   = 30 degrees");
        $display("cos_out = %0d", cos_out);
        $display("sin_out = %0d", sin_out);
        $display("----------------------------");


        #20;

        $finish;

    end

endmodule