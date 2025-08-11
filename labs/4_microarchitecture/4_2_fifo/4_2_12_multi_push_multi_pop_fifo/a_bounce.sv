module a_bounce #(parameter N = 3)

               (input clk, in_sig, output logic out_sig);
  logic [N-1:0]counter;

    always @(posedge clk)
      begin
      if (in_sig ^ out_sig) begin
          counter <= counter + 1;
          if (&counter) out_sig <= in_sig;
        end
          else counter <= 0;
     end
endmodule