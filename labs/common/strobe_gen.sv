// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"

module strobe_gen
# (
  parameter clk_mhz   = 50,
            strobe_hz = 3
)
(
  input        clk,
  input        rst,
  output logic strobe
);

  localparam period = clk_mhz * 1000 * 1000 / strobe_hz,
             w_cnt  = $clog2 (period);

  logic [w_cnt - 1:0] cnt;

  always_ff @ (posedge clk or posedge rst)
    if (rst)
    begin
      cnt    <= '0;
      strobe <= '0;
    end
    else if (cnt == '0)
    begin
      cnt    <= w_cnt' (period - 1);
      strobe <= '1;
    end
    else
    begin
      cnt    <= cnt - 1'd1;
      strobe <= '0;
    end

endmodule
