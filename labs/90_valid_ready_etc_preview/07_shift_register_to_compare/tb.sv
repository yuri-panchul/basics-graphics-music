`include "config.svh"

module tb;

    localparam width = 8, depth = 5;

    //------------------------------------------------------------------------

    logic               clk;
    logic               rst;

    logic               in_valid;
    logic [width - 1:0] in_data;

    logic               out_valid;
    logic [width - 1:0] out_data;

    logic [depth - 1:0]              debug_valid;
    logic [depth - 1:0][width - 1:0] debug_data;

    //------------------------------------------------------------------------

    shift_register_with_valid_and_debug
    # (
        .width (width),
        .depth (depth)
    )
    shift_register (.*);

    //------------------------------------------------------------------------

    initial
    begin
        clk = '0;
        forever #5 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        //--------------------------------------------------------------------
        // Initialization

        in_valid <= '0;

        //--------------------------------------------------------------------
        // Reset

        # 3 rst <= '1;
        repeat (5) @ (posedge clk);
        rst <= '0;

        //--------------------------------------------------------------------
        // Random stimuli

        repeat (100)
        begin
            in_valid <= $urandom ();
            in_data  <= $urandom ();

            @ (posedge clk);

            $write (".");

            if (in_valid)
                $write (" in: %h", in_data);
            else if (out_valid)
                $write ("       ");

            if (out_valid)
                $write (" out: %h", out_data);

            $display;
        end

        //--------------------------------------------------------------------
        $finish;
    end

endmodule
