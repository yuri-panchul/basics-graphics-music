module tb;

  logic clk;

  initial
  begin
    clk = '0;

    forever
      # 500 clk = ~ clk;
  end

  logic rst;

  initial
  begin
    rst <= 'x;
    repeat (2) @ (posedge clk);
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
  end

  logic vld, a, b, last, savl_sum;
  serial_adder_with_vld_and_last savl (.sum (savl_sum), .*);

  localparam n = 32;

  // Sequence of input values
  localparam [0 : n - 1] seq_vld      = 32'b0010_1100_0000_0000_0110_1111_1100_0111;
  localparam [0 : n - 1] seq_a        = 32'b0010_1000_0000_0000_0100_1001_1001_0110;
  localparam [0 : n - 1] seq_b        = 32'b0010_0000_0000_0000_0010_1010_1001_0110;
  localparam [0 : n - 1] seq_last     = 32'b0000_0000_0000_0000_0010_0001_0101_0010;

  // Expected sequence of correct output values
  localparam [0 : n - 1] seq_savl_sum = 32'b0000_0100_0000_0000_0110_0111_0100_0010;

  initial
  begin
    @ (negedge rst);

    for (int i = 0; i < n; i ++)
    begin
      vld  <= seq_vld  [i];
      a    <= seq_a    [i];
      b    <= seq_b    [i];
      last <= seq_last [i];

      @ (posedge clk);

      if (vld) begin
        $display ("vld %b, last %b, %b+%b=%b (expected %b)",
          vld, last, a, b,
          savl_sum, seq_savl_sum[i]);

        if (savl_sum !== seq_savl_sum[i])
        begin
          $display ("%s FAIL - see log above", `__FILE__);
          $finish;
        end
      end
      else
        // Testbench ignores output when vld is not set
        $display ("vld %b, last %b, %b+%b=%b", vld, last, a, b, savl_sum);
    end

    $display ("%s PASS", `__FILE__);
    $finish;
  end

endmodule
