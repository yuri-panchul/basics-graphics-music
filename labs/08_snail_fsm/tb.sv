module tb;

  logic     clk;
  logic     rst;
  logic [3:0] key;
  logic [7:0] sw;

  top i_top
  (
    .clk ( clk ),
    .rst ( rst ),
    .key ( key ),
    .sw  ( sw  )
  );

  initial
  begin
    clk = 1'b0;

    forever
      # 5 clk = ~ clk;
  end

  initial
  begin
    rst <= 1'bx;
    repeat (2) @ (posedge clk);
    rst <= 1'b1;
    repeat (2) @ (posedge clk);
    rst <= 1'b0;
  end

  initial
  begin
    `ifdef __ICARUS__
      $dumpvars;
    `endif

    key <= '0;
    sw  <= '0;

    @ (negedge rst);

    for (int i = 0; i < 50; i ++)
    begin
      // Enable override

      if (i == 20)
        force i_top.enable = 1'b1;
      else if (i == 40)
        release i_top.enable;

      @ (posedge clk);

      key <= $urandom ();
      sw  <= $urandom ();
    end

    $finish;
  end

endmodule
