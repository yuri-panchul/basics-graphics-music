module tb;

    logic       clk;
    logic [3:0] key;
    logic [7:0] sw;

    top i_top
    (
        .clk ( clk ),
        .key ( key ),
        .sw  ( sw  )
    );

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    logic reset;

    always_comb
        key [3] = ~ reset;

    initial
    begin
        reset <= 1'bx;
        repeat (2) @ (posedge clk);
        reset <= 1'b1;
        repeat (2) @ (posedge clk);
        reset <= 1'b0;
    end

    initial
    begin
        `ifdef __ICARUS__
            $dumpvars;
        `endif

        key [2:0] <= 'b0;
        sw        <= 'b0;

        @ (negedge reset);

        for (int i = 0; i < 50; i ++)
        begin
            // Enable override

            if (i == 20)
                force i_top.enable = 1'b1;
            else if (i == 40)
                release i_top.enable;

            @ (posedge clk);

            key [2:0] <= $urandom ();
            sw        <= $urandom ();
        end

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

endmodule
