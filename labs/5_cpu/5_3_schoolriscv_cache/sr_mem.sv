/*
 * schoolRISCV - small RISC-V CPU
 *
 * originally based on Sarah L. Harris MIPS CPU
 *                   & schoolMIPS project
 *
 * Copyright(c) 2017-2020 Stanislav Zhelnio
 *                        Aleksandr Romanov
 */

  module sr_mem (
  input logic clk,
  input logic rst,

  input   logic  [31:0]  ext_addr_i,
  input   logic          ext_req_i,
  output  logic          ext_rsp_o,
  output  logic  [127:0] ext_data_o,

  input  logic   [31:0] rom_data_i,
  output logic   [31:0] rom_addr_o
  );

  localparam DEPTH        = 1024;
  localparam AWIDTH       = 10;
  localparam RD_NUM       = 128/32;
  localparam MEM_DELAY    = 10;


  logic [AWIDTH -1:0]        ram_addr_ff;
  logic [31:0]               ram_dout;
  logic [1 :0]               read_ctr_ff;
  logic                      rd_trans_ff;
  logic [6 :0]               delay_ctr_ff;
  logic                      cl_data_en [RD_NUM -1:0];
  logic [31:0]               cl_data_ff [RD_NUM -1:0];

  genvar rd_idx;

  assign rom_addr_o = ext_req_i ? ext_addr_i : (ram_addr_ff + read_ctr_ff);

  always_ff @(posedge clk)
    if (rst) begin
      read_ctr_ff <= '0;
      rd_trans_ff <= '0;
      ram_addr_ff <= '0;
    end else begin
      rd_trans_ff <= ext_req_i | (rd_trans_ff & ~&read_ctr_ff);
      read_ctr_ff <= (rd_trans_ff | ext_req_i) ? 2'(read_ctr_ff + 2'b1) : read_ctr_ff;
      ram_addr_ff <= ext_req_i ? ext_addr_i[AWIDTH-1:0] : ram_addr_ff;
    end

  generate
    for (rd_idx = 0 ; rd_idx < RD_NUM;  rd_idx = rd_idx + 1) begin : g_rd

      assign cl_data_en[rd_idx] = (rd_trans_ff | ext_req_i) & (rd_idx == read_ctr_ff);

      always_ff @(posedge clk)
        if (cl_data_en[rd_idx])
          cl_data_ff[rd_idx] <= rom_data_i;

      assign ext_data_o[rd_idx*32+:32] = cl_data_ff[rd_idx] ;

    end : g_rd
  endgenerate

  // Primitive RAM Delay model
  always_ff @(posedge clk)
    if (rst)
      delay_ctr_ff <= '0;
    else if (ext_req_i | |(delay_ctr_ff))
      delay_ctr_ff <= ( delay_ctr_ff == MEM_DELAY ) ? '0 : 7'(delay_ctr_ff + 7'b1);

    assign ext_rsp_o = ( delay_ctr_ff == MEM_DELAY );
 endmodule
