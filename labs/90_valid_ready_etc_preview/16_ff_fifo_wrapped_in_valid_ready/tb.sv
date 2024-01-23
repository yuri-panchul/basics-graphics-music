`include "config.svh"

module tb
# (
    parameter width = 4, depth = 4
);

    //------------------------------------------------------------------------
    // Signals to drive Device Under Test - DUT

    logic clk;
    logic rst;

    // Upstream

    logic               up_valid;
    wire                up_ready;
    logic [width - 1:0] up_data;

    // Downstream

    wire                down_valid;
    logic               down_ready;
    wire  [width - 1:0] down_data;

    //------------------------------------------------------------------------
    // DUT instantiation

    ff_fifo_wrapped_in_valid_ready
    # (.width (width), .depth (depth))
    wrapped_fifo (.*);

    //------------------------------------------------------------------------
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

    //------------------------------------------------------------------------
    // Driving reset and control signals

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        //--------------------------------------------------------------------
        // Initialization

        up_valid   <= 1'b0;
        down_ready <= 1'b0;

        //--------------------------------------------------------------------
        // Reset

        repeat (3) @ (posedge clk);
        rst <= '1;
        repeat (3) @ (posedge clk);
        rst <= '0;

        //--------------------------------------------------------------------

        $display ("*** Run back-to-back");

        up_valid   <= 1'b1;
        down_ready <= 1'b1;

        repeat (20) @ (posedge clk);

        $display ("*** Filling the FIFO: up_valid=1, down_ready=0");

        up_valid   <= 1'b1;
        down_ready <= 1'b0;

        repeat (10) @ (posedge clk);

        $display ("*** Draining the FIFO: up_valid=0, down_ready=1");

        down_ready <= 1'b1;

        while (~ up_ready)  // Make sure up_valid went through
            @ (posedge clk);

        up_valid <= 1'b0;

        repeat (10) @ (posedge clk);

        $display ("*** Random up_valid and down_ready");

        repeat (50)
        begin
            if (~ up_valid | up_ready)
                up_valid <= $urandom ();

            down_ready <= $urandom ();

            @ (posedge clk);
        end

        $display ("*** Draining the FIFO: up_valid=0, down_ready=1");

        down_ready <= 1'b1;

        while (up_valid & ~ up_ready)  // Make sure up_valid went through
            @ (posedge clk);

        up_valid <= 1'b0;

        repeat (depth + 1) @ (posedge clk);

        //--------------------------------------------------------------------

        // TODO: $display ("*** Fill the FIFO and empty it");
        // START_SOLUTION

        $display ("*** Fill the FIFO and empty it");

        // END_SOLUTION

        // TODO: Set downstream ready to 1 to let the FIFO drain.
        // START_SOLUTION

        down_ready <= 1'b1;

        // END_SOLUTION

        // TODO: Properly drop/deassert upstream valid,
        // then wait until the FIFO is empty
        // (you can rely on 'down_valid' signal for it).
        // START_SOLUTION

        while (~ up_ready)
            @ (posedge clk);

        up_valid <= 1'b0;

        while (down_valid)
            @ (posedge clk);

        // END_SOLUTION

        // TODO: Set downstream ready to 0
        // START_SOLUTION

        down_ready <= 1'b0;

        // END_SOLUTION

        // TODO: Fill the FIFO with the 'depth' number of elements
        // (check that we have 'up_ready' at each cycle).
        // START_SOLUTION

        up_valid <= 1'b1;

        repeat (depth)
        begin
            @ (posedge clk);

            if (~ up_ready)
                $display ("ERROR: up_ready=1 is expected");
        end

        // END_SOLUTION

        // TODO: Drop upstream valid
        // START_SOLUTION

        up_valid <= 1'b0;

        // END_SOLUTION

        // TODO: Wait 10 'clk' cycles.
        // Every cycle check that the FIFO is still full
        // (use 'up_ready' for it).
        // START_SOLUTION

        repeat (10)
        begin
            @ (posedge clk);

            if (up_ready)
                $display ("ERROR: Unexpected up_ready, the FIFO is expected to be full");
        end

        // END_SOLUTION

        // TODO: Read 'depth' number of elements from the FIFO
        // and check that we have downstream valid at each cycle.
        // START_SOLUTION

        down_ready <= 1'b1;

        repeat (depth)
        begin
            @ (posedge clk);

            if (~ down_valid)
                $display ("ERROR: Unexpected down_valid");
        end

        // END_SOLUTION

        // TODO: Drop downstream ready.
        // START_SOLUTION

        down_ready <= 1'b0;

        // END_SOLUTION

        // TODO: Wait for 10 'clk' cycles.
        // Check every cycle that FIFO is still empty
        // (use 'down_valid' signal for it).

        // START_SOLUTION

        repeat (10)
        begin
            @ (posedge clk);

            if (down_valid)
                $display ("ERROR: The FIFO is expected to be empty");
        end

        // END_SOLUTION

        $finish;
    end

    //------------------------------------------------------------------------
    // Driving data

    always @ (posedge clk)
        if (rst)
            up_data <= '0;
        else if (up_valid & up_ready)
            up_data <= $urandom;

    //------------------------------------------------------------------------
    // Logging

    int unsigned cycle = 0;

    always @ (posedge clk)
    begin
        $write ("time %7d cycle %5d", $time, cycle ++);

        if ( rst        ) $write ( " rst"        ); else $write ( "    "        );

        if ( up_valid   ) $write ( " up_valid"   ); else $write ( "         "   );
        if ( up_ready   ) $write ( " up_ready"   ); else $write ( "         "   );

        if (up_valid & up_ready)
            $write (" %h", up_data);
        else
            $write ("  ");

        if ( down_valid ) $write ( " down_valid" ); else $write ( "           " );
        if ( down_ready ) $write ( " down_ready" ); else $write ( "           " );

        if (down_valid & down_ready)
            $write (" %h", down_data);
        else
            $write ("  ");

        $display;
    end

    //------------------------------------------------------------------------
    // Modeling and checking

    logic [width - 1:0] queue [$];
    logic [width - 1:0] down_data_expected;

    logic was_reset = 0;

    always @ (posedge clk)
    begin
        if (rst)
        begin
            queue = {};
            was_reset = 1;
        end
        else if (was_reset)
        begin
            if (up_valid & up_ready)
                queue.push_back (up_data);

            if (down_valid & down_ready)
            begin
                if (queue.size () == 0)
                begin
                    $display ("ERROR: unexpected downstream data %h", down_data);
                end
                else
                begin
                    `ifdef __ICARUS__
                        // Some version of Icarus has a bug, and this is a workaround
                        down_data_expected = queue [0];
                        queue.delete (0);
                    `else
                        down_data_expected = queue.pop_front ();
                    `endif

                    if (down_data_expected !== down_data)
                        $display ("ERROR: downstream data mismatch. Expected %h, actual %h",
                            down_data_expected, down_data);
                end
            end
        end
    end

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

endmodule
