// `include "decoder_pkg.sv"

module lsu(
  input logic clk_i,
  input logic rst_i,

  // Интерфейс к ядру
  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,

  // Интерфейс к памяти
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 3:0] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);

import decoder_pkg::*;

logic [1:0] byte_offset;
logic       half_offset;

assign byte_offset = core_addr_i[1:0];
assign half_offset = core_addr_i[1];

logic [31:0] rd_ldst_b, rd_ldst_bu, rd_ldst_h, rd_ldst_hu;

always_comb begin
  case(byte_offset)
    2'b00: rd_ldst_b = {{24{mem_rd_i[ 7]}}, mem_rd_i[ 7: 0]};
    2'b01: rd_ldst_b = {{24{mem_rd_i[15]}}, mem_rd_i[15: 8]};
    2'b10: rd_ldst_b = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
    2'b11: rd_ldst_b = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
  endcase
end

always_comb begin
  case(byte_offset)
    2'b00: rd_ldst_bu = {24'd0, mem_rd_i[ 7: 0]};
    2'b01: rd_ldst_bu = {24'd0, mem_rd_i[15: 8]};
    2'b10: rd_ldst_bu = {24'd0, mem_rd_i[23:16]};
    2'b11: rd_ldst_bu = {24'd0, mem_rd_i[31:24]};
  endcase
end

always_comb begin
  case(half_offset)
    1'b0: rd_ldst_h = {{16{mem_rd_i[15]}}, mem_rd_i[15: 0]};
    1'b1: rd_ldst_h = {{16{mem_rd_i[31]}}, mem_rd_i[31:16]};
  endcase
end

always_comb begin
  case(half_offset)
    1'b0: rd_ldst_hu = {16'd0, mem_rd_i[15: 0]};
    1'b1: rd_ldst_hu = {16'd0, mem_rd_i[31:16]};
  endcase
end

always_comb begin
  case(core_size_i)
    LDST_W : mem_be_o = 4'b1111;
    LDST_H : mem_be_o = half_offset ? 4'b1100 : 4'b0011;
    LDST_B : mem_be_o = 4'd1 << byte_offset;
    default: mem_be_o = '0;
  endcase
end

always_comb begin
  case(core_size_i)
    LDST_W : core_rd_o = mem_rd_i;
    LDST_B : core_rd_o = rd_ldst_b;
    LDST_BU: core_rd_o = rd_ldst_bu;
    LDST_H : core_rd_o = rd_ldst_h;
    LDST_HU: core_rd_o = rd_ldst_hu;
    default: core_rd_o = '0;
  endcase
end

always_comb begin
  case(core_size_i)
    LDST_B : mem_wd_o = {{4{core_wd_i[ 7:0]}}};
    LDST_H : mem_wd_o = {{2{core_wd_i[15:0]}}};
    LDST_W : mem_wd_o = core_wd_i;
    default: mem_wd_o = '0;
  endcase
end

logic stall;

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    stall <= 1'b0;
  end
  else begin
    stall <= core_stall_o;
  end
end

assign core_stall_o = (core_req_i & ~stall) ? 1'b1 :
                      (mem_ready_i) ? 1'b0 :
                      stall;
assign mem_req_o  = core_req_i;
assign mem_we_o   = core_we_i;
assign mem_addr_o = core_addr_i;

endmodule
