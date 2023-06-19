// Asynchronous reset here is needed for the FPGA board we use

module strobe_gen
# (
  parameter width = 0
)
(
  input  clk,
  input  rst,
  output strobe
);

  logic [width - 1:0] cnt;

  always_ff @ (posedge clk or posedge rst)
    if (rst)
      cnt <= '0;
    else
      cnt <= cnt + width' (1);

  assign strobe = ~| cnt;  // Same as (cnt == '0)

endmodule
