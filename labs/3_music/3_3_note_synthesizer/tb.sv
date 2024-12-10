`include "config.svh"

module tb;

    localparam clk_mhz = 50,
               w_key   = 4,
               w_sw    = 4,
               w_led   = 8,
               w_digit = 8,
               w_gpio  = 100;

    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;
    logic [3:0] key;
    logic [3:0] sw;

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
            # 1 clk = ! clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 'bx;
        repeat (2) @ (posedge clk);
        rst <= 1;
        repeat (2) @ (posedge clk);
        rst <= 0;
    end

    //------------------------------------------------------------------------

    always_comb
        key = { {(w_key - 1){1'b0}} , ~ rst};

    initial
    begin
        #0
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        #400000

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule
