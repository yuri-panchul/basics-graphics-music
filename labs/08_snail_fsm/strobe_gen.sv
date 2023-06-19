// Asynchronous reset here is needed for some FPGA boards we use

module strobe_gen
# (
  parameter clk_mhz          = 50,
            n_times_a_second = 3,
            width            = $clog2 (clk_mhz * 1000000 / n_times_a_second)
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

  // Exercise: Make this strobe generation precise

endmodule
