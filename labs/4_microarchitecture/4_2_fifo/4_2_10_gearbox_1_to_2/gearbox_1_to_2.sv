// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module gearbox_1_to_2
# (
  parameter width = 0
)
(
  input                    clk,
  input                    rst,

  input                    up_vld,    // upstream
  output                   up_rdy,
  input  [    width - 1:0] up_data,

  output                   down_vld,  // downstream
  input                    down_rdy,
  output [2 * width - 1:0] down_data
);

  // See https://habr.com/ru/post/693568/ for the problem description

  logic               half_vld;
  logic [width - 1:0] half;

  always_ff @ (posedge clk or posedge rst)
    if (rst)
      half_vld <= '0;
    else if (up_vld & up_rdy)
      half_vld <= ~ half_vld;

  always_ff @ (posedge clk)
    if (up_vld & up_rdy & ~ half_vld)
      half <= up_data;

  assign down_vld  = half_vld & up_vld;
  assign down_data = { half, up_data };

  assign up_rdy = ~ half_vld | down_rdy;

endmodule
