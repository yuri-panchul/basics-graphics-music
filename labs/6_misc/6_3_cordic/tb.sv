`include "config.svh"

module tb;

   localparam width = 16;

   localparam real accuracy = 0.01,
                   pi       = 3.14159265358979323846;

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic                            clk;
    logic                            rst;

    logic                            start;
    logic              [width - 1:0] angle;

    wire                             calc;    // Is calculating
    wire                             finish;  // Finished calculating

    wire  logic signed [width - 1:0] cos_out;
    wire  logic signed [width - 1:0] sin_out;

    //--------------------------------------------------------------------------
    // DUT instantiation

    cordic dut (.*);

    //--------------------------------------------------------------------------
    // Driving clock

    initial
    begin
        clk = '1;
        forever #5 clk = ~ clk;
    end

    initial
    begin
        repeat (10000) @ (posedge clk);
        $display ("Timeout!");
        $finish;
    end

    //--------------------------------------------------------------------------
    // Checking the finish signal

    logic is_rst = 1'b0;

    always @ (posedge clk)
        if (rst)
            is_rst <= 1'b1;
        else if (is_rst)
            assert (~ $isunknown (finish));

    //--------------------------------------------------------------------------
    // Tests

    task test (logic [15:0] t_angle);

        real f_angle, f_sin_out, f_cos_out,
                      f_sin_exp, f_cos_exp,
                      f_sin_dif, f_cos_dif;

        assert (~ $isunknown (t_angle));

        start <= 1'b1;
        angle <= t_angle;

        @ (posedge clk);

        start <= 1'b0;
        angle <= 'x;

        while (~ finish)
            @ (posedge clk);

        assert (~ $isunknown (sin_out));
        assert (~ $isunknown (cos_out));

        f_angle   = t_angle;

        f_sin_out = real' (sin_out) / (1 << width);
        f_cos_out = real' (cos_out) / (1 << width);

        f_sin_exp = $sin (angle);
        f_cos_exp = $cos (angle);

        f_sin_dif = $abs (f_sin_out - f_sin_exp);
        f_cos_dif = $abs (f_cos_out - f_cos_exp);

        if (f_sin_dif > f_sin_exp * accuracy)
        begin
            $display ("ERROR: sin: %f (%h) expected: %f",
                f_sin_out, sin_out, f_sin_exp);

            $finish;
        end

        if (f_cos_dif > f_cos_exp * accuracy)
        begin
            $display ("ERROR: cos: %f (%h) expected: %f",
                f_cos_out, cos_out, f_cos_exp);

            $finish;
        end
    endtask

    //--------------------------------------------------------------------------
    // Driving reset and control signals

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        //------------------------------------------------------------------------
        // Initialization

        start <= 1'b0;
        angle <= 'x;

        //------------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

        //------------------------------------------------------------------------
        // Tests

        for (int i = 0; i < (1 << width); i += 1000)
            test (i);

        repeat (100)
            test ($urandom_range (0, (1 << width) - 1));

        $finish;
    end

    //--------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("time %7d cycle %5d", $time, cycle ++);

        if (rst)
            $write (" rst");
        else
            $write ("    ");

        if (is_rst)
        begin
            if (start === 1'b1)
                $write (" angle %h %f", angle, real' (angle) / (1 << width));
            else
                $write ("                           ");

            if (finish === 1'b1)
                $write (" sin %h %f cos %h %f",
                    sin_out, real' (sin_out) / (1 << width),
                    cos_out, real' (cos_out) / (1 << width));
        end

        $display;
    end

    //----------------------------------------------------------------------
    // Performance counters

    logic [32:0] n_cycles, start_cnt, finish_cnt, finish_vld, finish_rdy;

    always @ (posedge clk)
        if (rst)
        begin
            n_cycles   <= '0;
            start_cnt  <= '0;
            finish_cnt <= '0;
        end
        else
        begin
            n_cycles <= n_cycles + 1'd1;

            if (start)
                start_cnt <= start_cnt + 1'd1;

            if (finish_vld & finish_rdy)
                finish_cnt <= finish_cnt + 1'd1;
        end

    //----------------------------------------------------------------------

    final
        $display ("\n\nnumber of transfers : start %0d finish %0d per %0d cycles",
            start_cnt, finish_cnt, n_cycles);

endmodule
