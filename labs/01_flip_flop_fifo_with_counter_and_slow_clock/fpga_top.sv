// Asynchronous reset here is needed for the FPGA board we use

`include "config.svh"

module fpga_top
(
  input              clk,
  input              reset_n,

  input        [3:0] key_sw,
  output       [3:0] led,

  output logic [7:0] abcdefgh,
  output       [3:0] digit,

  output             buzzer,

  output             hsync,
  output             vsync,
  output       [2:0] rgb
);

  //--------------------------------------------------------------------------

  wire rst = ~ reset_n;

  assign led    = '1;
  assign buzzer = 1'b1;
  assign hsync  = 1'b1;
  assign vsync  = 1'b1;
  assign rgb    = 3'b0;

  //--------------------------------------------------------------------------

  `ifdef SIMULATION

    wire slow_clk = clk;

  `else

    wire slow_clk_raw, slow_clk;

    slow_clk_gen # (26) i_slow_clk_gen (.slow_clk_raw (slow_clk_raw), .*);

    // "global" is Intel FPGA-specific primitive to route
    // a signal coming from data into clock tree

    global i_global (.in (slow_clk_raw), .out (slow_clk));

  `endif  // `ifdef SIMULATION

  //--------------------------------------------------------------------------

  localparam fifo_width = 4, fifo_depth = 4;

  wire [fifo_width - 1:0] write_data;
  wire [fifo_width - 1:0] read_data;
  wire empty, full;

  // Either of two leftmost keys is pressed
  wire push = ~ full & key_sw [3:2] != 2'b11;

  // Either of two rightmost keys is pressed
  wire pop  = ~ empty & key_sw [1:0] != 2'b11;

  // With this implementation of FIFO
  // we can actually push into a full FIFO
  // if we are performing pop in the same cycle.
  //
  // However we are not going to do this
  // because we assume that the logic that pushes
  // is separated from the logic that pops.
  //
  // wire push = (~ full | pop) & key_sw [3:2] != 2'b11;

  wire [31:0] debug;

  //--------------------------------------------------------------------------

  `ifdef __ICARUS__

    logic [fifo_width - 1:0] write_data_const_array [0:2 ** fifo_width - 1];

    assign write_data_const_array [ 0] = 4'h2;
    assign write_data_const_array [ 1] = 4'h6;
    assign write_data_const_array [ 2] = 4'hd;
    assign write_data_const_array [ 3] = 4'hb;
    assign write_data_const_array [ 4] = 4'h7;
    assign write_data_const_array [ 5] = 4'he;
    assign write_data_const_array [ 6] = 4'hc;
    assign write_data_const_array [ 7] = 4'h4;
    assign write_data_const_array [ 8] = 4'h1;
    assign write_data_const_array [ 9] = 4'h0;
    assign write_data_const_array [10] = 4'h9;
    assign write_data_const_array [11] = 4'ha;
    assign write_data_const_array [12] = 4'hf;
    assign write_data_const_array [13] = 4'h5;
    assign write_data_const_array [14] = 4'h8;
    assign write_data_const_array [15] = 4'h3;

  `else

    // New SystemVerilog syntax for array assignment

    wire [fifo_width - 1:0] write_data_const_array [0:2 ** fifo_width - 1]
      = '{ 4'h2, 4'h6, 4'hd, 4'hb, 4'h7, 4'he, 4'hc, 4'h4,
           4'h1, 4'h0, 4'h9, 4'ha, 4'hf, 4'h5, 4'h8, 4'h3 };

  `endif

  //--------------------------------------------------------------------------

  wire [fifo_width - 1:0] write_data_index;

  counter_with_enable # (fifo_width) i_counter
  (
    .clk    (slow_clk),
    .enable (push),
    .cnt    (write_data_index),
    .*
  );

  assign write_data = write_data_const_array [write_data_index];

  //--------------------------------------------------------------------------

  flip_flop_fifo_with_counter
  # (
    .width (fifo_width),
    .depth (fifo_depth)
  )
  i_fifo (.clk (slow_clk), .*);

  wire [3:0] wr_ptr = debug [19:16];
  wire [3:0] rd_ptr = debug [ 3: 0];

  //--------------------------------------------------------------------------

  wire [7:0] abcdefgh_pre;

  seven_segment_4_digits i_display
  (
    .clk      (clk),
    .number   ({ write_data , wr_ptr , rd_ptr , read_data }),
    .dots     (4'b0),
    .abcdefgh (abcdefgh_pre),
    .digit    (digit),
    .*
  );

  localparam sign_full  = 8'b01111111,
             sign_empty = 8'b11101111;

  always_comb
    if (digit == 4'b1110 & empty)
      abcdefgh = sign_empty;
    else if (digit == 4'b0111 & full)
      abcdefgh = sign_full;
    else
      abcdefgh = abcdefgh_pre;

endmodule
