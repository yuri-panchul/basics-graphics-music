// `include "decoder_pkg.sv"

module decoder (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);
import decoder_pkg::*;

logic [2:0] func3;
logic [6:0] func7;
logic [4:0] opcode;

logic is_ariphm_op, is_shamt, is_add, is_sr;
assign is_add = func3 == ALU_ADD;
assign is_shamt = func3[1:0] == 2'b01;
assign is_sr = func3 == 3'b101;
assign is_ariphm_op = is_add | is_sr;
assign func3  = fetched_instr_i[14:12];
assign func7  = fetched_instr_i[31:25];
assign opcode = fetched_instr_i[ 6: 2];

always_comb begin
  a_sel_o         = OP_A_RS1;
  b_sel_o         = OP_B_RS2;
  alu_op_o        = ALU_ADD;
  csr_op_o        = 0;
  csr_we_o        = 0;
  mem_req_o       = 0;
  mem_we_o        = 0;
  mem_size_o      = LDST_B;
  gpr_we_o        = 0;
  wb_sel_o        = WB_EX_RESULT;
  illegal_instr_o = 0;
  branch_o        = 0;
  jal_o           = 0;
  jalr_o          = 0;
  mret_o          = 0;
  if(fetched_instr_i[1:0] == 2'b11) begin
    case(opcode)
      OP_OPCODE: begin
        alu_op_o = {1'b0, func7[5], func3};
        gpr_we_o = 1'b1;
        illegal_instr_o = 1'b1;
        if(((func7 == 7'b0100000) && is_ariphm_op) | (func7 == 7'b0)) begin
          illegal_instr_o = 1'b0;
        end
      end
      OP_IMM_OPCODE: begin
        b_sel_o  = OP_B_IMM_I;
        alu_op_o = {1'b0, is_shamt ? func7[5] : 1'b0, func3};
        gpr_we_o = 1'b1;
        if(((func7 !=? 7'b0?00000) && is_sr) | ((func7 != 7'b0000000) && (func3 == 3'b001))) begin
          illegal_instr_o = 1'b1;
        end
      end
      LUI_OPCODE: begin
        a_sel_o = OP_A_ZERO;
        b_sel_o = OP_B_IMM_U;
        gpr_we_o= 1'b1;
      end
      LOAD_OPCODE: begin
        b_sel_o   = OP_B_IMM_I;
        wb_sel_o  = WB_LSU_DATA;
        gpr_we_o  = 1'b1;
        mem_req_o = 1'b1;
        mem_size_o= func3;
        // Если func3 == 3/6/7 (2 + 1/4/5)
        if(func3[1] & (func3[2] | func3[0])) begin
          illegal_instr_o = 1'b1;
        end
      end
      STORE_OPCODE: begin
        b_sel_o   = OP_B_IMM_S;
        mem_req_o = 1'b1;
        mem_we_o  = 1'b1;
        mem_size_o= func3;
        if(func3 >= 3'd3) begin
          illegal_instr_o = 1'b1;
        end
      end
      BRANCH_OPCODE: begin
        alu_op_o = {2'b11, func3};
        branch_o = 1'b1;
        if(func3[2:1] == 2'b01) begin
          illegal_instr_o = 1'b1;
        end
      end
      JAL_OPCODE: begin
        a_sel_o = OP_A_CURR_PC;
        b_sel_o = OP_B_INCR;
        gpr_we_o= 1'b1;
        jal_o   = 1'b1;
      end
      JALR_OPCODE: begin
        a_sel_o = OP_A_CURR_PC;
        b_sel_o = OP_B_INCR;
        gpr_we_o= 1'b1;
        jalr_o  = 1'b1;
        if(func3 != 3'b0) begin
          illegal_instr_o = 1'b1;
        end
      end
      AUIPC_OPCODE: begin
        a_sel_o = OP_A_CURR_PC;
        b_sel_o = OP_B_IMM_U;
        gpr_we_o= 1'b1;
      end
      MISC_MEM_OPCODE: begin
        if(func3 != 3'b000) begin
          illegal_instr_o = 1'b1;
        end
      end
      SYSTEM_OPCODE: begin
        if(func3[1:0] == 2'b00) begin
          if(fetched_instr_i == 32'h30200073) begin
            mret_o = 1'b1;
          end
          else begin
            illegal_instr_o = 1'b1;
          end
        end
        else begin
          csr_op_o = func3;
          csr_we_o = 1'b1;
          wb_sel_o = WB_CSR_DATA;
          gpr_we_o = 1'b1;
        end
      end
      default: illegal_instr_o = 1'b1;
    endcase
  end
  else begin
    illegal_instr_o = 1'b1;
  end
  if(illegal_instr_o) begin
    csr_we_o = 1'b0;
    mem_req_o= 1'b0;
    mem_we_o = 1'b0;
    gpr_we_o = 1'b0;
    branch_o = 1'b0;
    jal_o    = 1'b0;
    jalr_o   = 1'b0;
    mret_o   = 1'b0;
  end
end


endmodule
