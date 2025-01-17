// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module gearbox_2_to_1
# (
  parameter width = 0
)
(
  input                    clk,
  input                    rst,

  input                    up_vld,    // upstream
  output                   up_rdy,
  input  [2 * width - 1:0] up_data,

  output                   down_vld,  // downstream
  input                    down_rdy,
  output [    width - 1:0] down_data
);

  // TODO:
  //
  // The opposite of the problem described in
  // https://habr.com/ru/post/693568/
  //
  // You can use exam_2_gearbox_1_to_2 as an example.

  // START_SOLUTION

  logic               half_vld;
  logic [width - 1:0] half;

  always_ff @ (posedge clk or posedge rst)
    if (rst)
      half_vld <= '0;
    else if (down_vld & down_rdy)
      half_vld <= ~ half_vld;

  assign down_vld  = up_vld;

  assign down_data
    = half_vld ?
        up_data [    0 +: width]
      : up_data [width +: width];

  assign up_rdy = half_vld & down_rdy;

  // END_SOLUTION

endmodule
