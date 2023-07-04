// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module slow_clk_gen
# (
  parameter fast_clk_mhz = 50,
            slow_clk_hz  = 3
)
(
  input        clk,
  input        rst,
  output logic slow_clk_raw
);

  localparam half_period = fast_clk_mhz * 1000 * 1000 / slow_clk_hz / 2,
             w_cnt = $clog2 (half_period);

  logic [w_cnt - 1:0] cnt;

  always_ff @ (posedge clk or posedge rst)
    if (rst)
    begin
      cnt          <= '0;
      slow_clk_raw <= '0;
    end
    else if (cnt == '0)
    begin
      cnt <= w_cnt' (half_period - 1);
      slow_clk_raw <= ~ slow_clk_raw;
    end
    else
    begin
      cnt <= cnt - 1'd1;
    end

  // Note! You have to pass this clock though
  // "global" primitive in Intel FPGA
  // or BUFG  primitive in Xilinx Vivado

endmodule
