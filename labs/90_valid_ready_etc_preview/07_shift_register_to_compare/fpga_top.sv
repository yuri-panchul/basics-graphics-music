// Asynchronous reset here is needed for the FPGA board we use

`include "config.vh"

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

  localparam width = 4, depth = 4;

  wire               in_valid = (key_sw != 4'b1111);  // Any key is pressed
  wire [width - 1:0] in_data;

  wire               out_valid;
  wire [width - 1:0] out_data;


  wire [depth - 1:0]              debug_valid;
  wire [depth - 1:0][width - 1:0] debug_data;

  wire [depth - 1:0]              debug_valid_mirrored;
  wire [depth - 1:0][width - 1:0] debug_data_mirrored;

  generate
    genvar i;

    for (i = 0; i < depth; i++)
    begin : gen
      assign debug_valid_mirrored [i] = debug_valid [depth - 1 - i];
      assign debug_data_mirrored  [i] = debug_data  [depth - 1 - i];
    end

  endgenerate

  //--------------------------------------------------------------------------

  `ifdef __ICARUS__

    logic [width - 1:0] in_data_const_array [0:2 ** width - 1];

    assign in_data_const_array [ 0] = 4'h2;
    assign in_data_const_array [ 1] = 4'h6;
    assign in_data_const_array [ 2] = 4'hd;
    assign in_data_const_array [ 3] = 4'hb;
    assign in_data_const_array [ 4] = 4'h7;
    assign in_data_const_array [ 5] = 4'he;
    assign in_data_const_array [ 6] = 4'hc;
    assign in_data_const_array [ 7] = 4'h4;
    assign in_data_const_array [ 8] = 4'h1;
    assign in_data_const_array [ 9] = 4'h0;
    assign in_data_const_array [10] = 4'h9;
    assign in_data_const_array [11] = 4'ha;
    assign in_data_const_array [12] = 4'hf;
    assign in_data_const_array [13] = 4'h5;
    assign in_data_const_array [14] = 4'h8;
    assign in_data_const_array [15] = 4'h3;

  `else

    // New SystemVerilog syntax for array assignment

    wire [width - 1:0] in_data_const_array [0:2 ** width - 1]
      = '{ 4'h2, 4'h6, 4'hd, 4'hb, 4'h7, 4'he, 4'hc, 4'h4,
           4'h1, 4'h0, 4'h9, 4'ha, 4'hf, 4'h5, 4'h8, 4'h3 };

  `endif

  //--------------------------------------------------------------------------

  wire [width - 1:0] in_data_index;

  counter_with_enable # (width) i_counter
  (
    .clk    (slow_clk),
    .enable (in_valid),
    .cnt    (in_data_index),
    .*
  );

  assign in_data = in_data_const_array [in_data_index];

  //--------------------------------------------------------------------------

  shift_register_with_valid_and_debug
  # (
    .width (width),
    .depth (depth)
  )
  i_fifo (.clk (slow_clk), .*);

  //--------------------------------------------------------------------------

  wire [7:0] abcdefgh_pre;

  seven_segment_4_digits i_display
  (
    .clk      (clk),
    .number   (debug_data_mirrored),
    .dots     (4'b0),
    .abcdefgh (abcdefgh_pre),
    .digit    (digit),
    .*
  );

  //--------------------------------------------------------------------------

  localparam sign_empty_entry = 8'b11111111;

  always_comb
    if ((digit | debug_valid_mirrored) != 4'b1111)
      abcdefgh = sign_empty_entry;
    else
      abcdefgh = abcdefgh_pre;

endmodule
