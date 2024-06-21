`include "config.svh"

module tb
# (
    parameter width = 16
);

    //--------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic clk;
    logic rst;

    // Upstream

    logic               up_vld;
    wire                up_rdy;
    logic [width - 1:0] up_data;

    // Downstream

    wire                down_vld;
    logic               down_rdy;
    wire  [width - 1:0] down_data;

    //--------------------------------------------------------------------------
    // DUT instantiation

    pow_5_pipelined # (.width (width)) dut (.*);

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
    // Driving reset and control signals

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        //------------------------------------------------------------------------
        // Initialization

        up_vld   <= 1'b0;
        down_rdy <= 1'b0;

        //------------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

        //------------------------------------------------------------------------

        $display ("*** Run back-to-back");

        up_vld   <= 1'b1;
        down_rdy <= 1'b1;

        repeat (20) @ (posedge clk);

        $display ("*** Filling the pipeline: up_vld=1, down_rdy=0");

        // up_vld is still 1'b1;
        down_rdy <= 1'b0;

        repeat (10) @ (posedge clk);

        $display ("*** Draining the pipeline: up_vld=0, down_rdy=1");

        // up_vld is still 1'b1;
        down_rdy <= 1'b1;

        while (~ up_rdy)    // Need to keep up_vld until up_rdy
            @ (posedge clk);

        up_vld <= 1'b0;     // Release up_vld

        repeat (10) @ (posedge clk);

        $display ("*** Random up_vld and down_rdy");

        repeat (50)
        begin
            if (~ up_vld | up_rdy)
                up_vld <= $urandom ();

            down_rdy <= $urandom ();

            @ (posedge clk);
        end

        $display ("*** Draining the pipeline: up_vld=0, down_rdy=1");

        down_rdy <= 1'b1;

        while (up_vld & ~ up_rdy)  // Need to keep up_vld until up_rdy
            @ (posedge clk);

        up_vld <= 1'b0;

        repeat (10) @ (posedge clk);

        //------------------------------------------------------------------------

        $finish;
    end

    //--------------------------------------------------------------------------
    // Driving data

    always @ (posedge clk)
        if (rst)
            up_data <= '0;
        else if (up_vld & up_rdy)
            up_data <= $urandom_range (0, 9);

    //--------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("time %7d cycle %5d", $time, cycle ++);

        if ( rst      ) $write ( " rst"      ); else $write ( "    "      );

        if ( up_vld   ) $write ( " up_vld"   ); else $write ( "       "   );
        if ( up_rdy   ) $write ( " up_rdy"   ); else $write ( "       "   );

        if (up_vld & up_rdy)
            $write (" %5d", up_data);
        else
            $write ("      ");

        if ( down_vld ) $write ( " down_vld" ); else $write ( "         " );
        if ( down_rdy ) $write ( " down_rdy" ); else $write ( "         " );

        if (down_vld & down_rdy)
            $write (" %5d", down_data);
        else
            $write ("      ");

        $display;
    end

    //--------------------------------------------------------------------------
    // Modeling and checking

    logic [width - 1:0] queue [$];
    logic [width - 1:0] down_data_expected;

    // Additional signals to have the comparison on the waveform

    logic comparison_moment;
    logic [width - 1:0] down_data_compared;

    logic was_reset = 0;

    always @ (posedge clk)
    begin
        comparison_moment = '0;

        if (rst)
        begin
            queue = {};
            was_reset = 1;
        end
        else if (was_reset)
        begin
            if (up_vld & up_rdy)
                queue.push_back (up_data);

            if (down_vld & down_rdy)
            begin
                if (queue.size () == 0)
                begin
                    $display ("ERROR: unexpected downstream data %0d", down_data);
                end
                else
                begin
                    `ifdef __ICARUS__
                        // Some version of Icarus has a bug, and this is a workaround
                        down_data_expected = queue [0] ** 5;
                        queue.delete (0);
                    `else
                        down_data_expected = queue.pop_front () ** 5;
                    `endif

                    if (down_data !== down_data_expected)
                        $display ("ERROR: downstream data mismatch. Expected %0d, actual %0d",
                            down_data_expected, down_data);

                    // Additional assignments to have the comparison on the waveform

                    comparison_moment  <= '1;
                    down_data_compared <= down_data;
                end
            end
        end
    end

    //----------------------------------------------------------------------

    final
    begin
        if (queue.size () != 0)
        begin
            $write ("ERROR: data is left sitting in the model queue:");

            for (int i = 0; i < queue.size (); i ++)
                $write (" %h", queue [queue.size () - i - 1]);

            $display;
        end
    end

    //----------------------------------------------------------------------
    // Performance counters

    logic [32:0] n_cycles, up_cnt, down_cnt;

    always @ (posedge clk)
        if (rst)
        begin
            n_cycles <= '0;
            up_cnt   <= '0;
            down_cnt <= '0;
        end
        else
        begin
            n_cycles <= n_cycles + 1'd1;

            if (up_vld & up_rdy)
                up_cnt <= up_cnt + 1'd1;

            if (down_vld & down_rdy)
                down_cnt <= down_cnt + 1'd1;
        end

    //----------------------------------------------------------------------

    final
        $display ("\n\nnumber of transfers : up %0d down %0d per %0d cycles",
            up_cnt, down_cnt, n_cycles);

endmodule
