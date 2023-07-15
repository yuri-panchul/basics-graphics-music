module tb;

    logic       clk;
    logic       reset_n;
    logic [3:0] key_sw;
    logic       rx;

    top
    # (
        .clk_frequency      (   50 ),
        .baud_rate          (    1 ),
        .timeout_in_seconds ( 1000 )
    )
    i_top
    (
        .clk     ( clk     ),
        .reset_n ( reset_n ),
        .key_sw  ( key_sw  ),
        .rx      ( rx      )
    );

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    initial
    begin
        reset_n <= 1'bx;
        repeat (2) @ (posedge clk);
        reset_n <= 1'b0;
        repeat (2) @ (posedge clk);
        reset_n <= 1'b1;
    end

    initial
    begin

        `ifdef __ICARUS__
            $dumpvars;
        `endif

        key_sw <= 4'b0;

        @ (posedge reset_n);

        for (int i = 0; i < 50; i ++)
        begin
            @ (posedge clk);

            key_sw <= $urandom ();
            rx     <= $urandom ();
        end

        `ifdef MODEL_TECH  // Mentor ModelSim and Questa
            $stop;
        `else
            $finish;
        `endif
    end

    logic       in_valid;
    logic [7:0] in_char;

    hex_parser i_parser
    (
        .clk      (   clk      ),
        .reset    ( ~ reset_n  ),
        .in_valid (   in_valid ),
        .in_char  (   in_char  )
    );

    initial
    begin
        in_valid <= 1'b0;

        @ (posedge reset_n);

        for (int i = 0; i < 50; i ++)
        begin
            @ (posedge clk);

            in_valid <= 1'b1;
            in_char  <= "0" + i % 10;
        end
    end

endmodule
