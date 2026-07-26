// `include "csr_pkg.sv"

module csr_controller(

  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,

  input  logic [ 2:0] opcode_i,

  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,

  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);

import csr_pkg::*;

logic [31:0] write_data;

logic [31:0] mie, mtvec, mscratch, mepc, mcause;

assign mie_o    = mie;
assign mepc_o   = mepc;
assign mtvec_o  = mtvec;

logic mie_en, mtvec_en, mscratch_en, mepc_en, mcause_en;

assign mie_en       =  write_enable_i & (addr_i == MIE_ADDR      );
assign mtvec_en     =  write_enable_i & (addr_i == MTVEC_ADDR    );
assign mscratch_en  =  write_enable_i & (addr_i == MSCRATCH_ADDR );
assign mepc_en      = (write_enable_i & (addr_i == MEPC_ADDR     )) | trap_i;
assign mcause_en    = (write_enable_i & (addr_i == MCAUSE_ADDR   )) | trap_i;

always_comb begin
  case(opcode_i)
    CSR_RW : write_data = rs1_data_i;
    CSR_RS : write_data = rs1_data_i | read_data_o;
    CSR_RC : write_data = ~rs1_data_i & read_data_o;
    CSR_RWI: write_data = imm_data_i;
    CSR_RSI: write_data = imm_data_i | read_data_o;
    CSR_RCI: write_data = ~imm_data_i & read_data_o;
    default: write_data = '0;
  endcase
end

always_comb begin
  case(addr_i)
      12'h304: read_data_o = mie;
      12'h305: read_data_o = mtvec;
      12'h340: read_data_o = mscratch;
      12'h341: read_data_o = mepc;
      12'h342: read_data_o = mcause;
      default: read_data_o = '0;
  endcase
end

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    mie <= 1'b0;
  end
  else if(mie_en) begin
    mie <= write_data;
  end
end

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    mtvec <= 1'b0;
  end
  else if(mtvec_en) begin
    mtvec <= write_data;
  end
end

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    mscratch <= 1'b0;
  end
  else if(mscratch_en) begin
    mscratch <= write_data;
  end
end

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    mepc <= 1'b0;
  end
  else if(mepc_en) begin
    mepc <= trap_i ? pc_i : write_data;
  end
end

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    mcause <= 1'b0;
  end
  else if(mcause_en) begin
    mcause <= trap_i ? mcause_i : write_data;
  end
end

endmodule
