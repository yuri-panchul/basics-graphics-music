`include "config.svh"

// sv_file_list.f lists tb.sv for the Icarus simulation. The Vivado flow
// reads the same list for synthesis, where config.svh defines SYNTHESIS
// instead of SIMULATION, so the testbench is skipped there.

`ifdef SIMULATION

module tb;

    localparam clk_mhz = 1,
               w_key   = 4,
               w_sw    = 8,
               w_led   = 8,
               w_digit = 8,
               w_gpio  = 100;

    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;
    logic [3:0] key;
    logic [7:0] sw;

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_lab_top
    (
        .clk      ( clk ),
        .slow_clk ( clk ),
        .rst      ( rst ),
        .key      ( key ),
        .sw       ( sw  )
    );

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars (0, tb);
        `endif

        key <= '0;
        sw  <= '0;

        @ (negedge rst);

        repeat (50)
        begin
            @ (posedge clk);

            key <= $urandom ();
            sw  <= $urandom ();
        end

        $finish;
    end

endmodule

`endif  // ifdef SIMULATION
