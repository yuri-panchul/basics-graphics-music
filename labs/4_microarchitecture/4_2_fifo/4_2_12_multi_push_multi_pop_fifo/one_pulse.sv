module one_pusle(input clk, in_sig, output logic out_sig);
  logic [1:0] a;
    always_ff @(posedge clk)begin
    a       <= {a[0],in_sig};
    out_sig <= a[1] & in_sig;
  end
endmodule