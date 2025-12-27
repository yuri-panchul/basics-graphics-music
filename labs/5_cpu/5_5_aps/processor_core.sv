// `include "decoder_pkg.sv"

module processor_core (

  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  input  logic        irq_req_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o,
  output logic        irq_ret_o,
  output logic        trap_o
);

/*
  =====================================================
  Inmodule declarations
  =====================================================
*/
import decoder_pkg::*;
logic [31:0] imm_I, imm_U, imm_S, imm_B, imm_J, imm_Z;
logic [31:0] PC, jalr_sum, pc_add;
logic not_a_stall, trap;
//=====================================================

/*
  =====================================================
  Register file ports declarations
  =====================================================
*/
logic [ 4:0] read_addr1_i, read_addr2_i, write_addr_i;
logic [31:0] read_data1_o, read_data2_o, write_data_i;
logic write_enable_i;
//=====================================================



/*
  =====================================================
  Decoder ports declarations
  =====================================================
*/
logic [1:0]   a_sel_o;
logic [2:0]   b_sel_o;
logic [4:0]   alu_op_o;
logic         gpr_we_o;
logic [1:0]   wb_sel_o;
logic         branch_o;
logic         jal_o;
logic         jalr_o;
logic         mret_o;
logic [2:0]   csr_op_o;
logic         csr_we_o;
logic         illegal_instr_o;
//=====================================================



/*
  =====================================================
  CSR ports declarations
  =====================================================
*/
logic [31:0]  mcause;
logic [31:0]  csr_wd;
logic [31:0]  mie_o, mepc_o, mtvec_o;
//=====================================================



/*
  =====================================================
  IRQ ports declarations
  =====================================================
*/
logic         irq_o;
logic [31:0]  irq_cause_o;
//=====================================================



/*
  =====================================================
  ALU ports signals
  =====================================================
*/
logic [31:0] a_i;
logic [31:0] b_i;
logic [ 4:0] alu_op_i;
logic        flag_o;
logic [31:0] result_o;

assign alu_op_i = alu_op_o;

always_comb begin
  priority case(a_sel_o)
    OP_A_RS1    : a_i = read_data1_o;
    OP_A_CURR_PC: a_i = PC;
    OP_A_ZERO   : a_i = 32'd0;
  endcase
end

always_comb begin
  priority case(b_sel_o)
    OP_B_RS2    : b_i = read_data2_o;
    OP_B_IMM_I  : b_i = imm_I;
    OP_B_IMM_U  : b_i = imm_U;
    OP_B_IMM_S  : b_i = imm_S;
    OP_B_INCR   : b_i = 32'd4;
  endcase
end
//=====================================================




/*
  =====================================================
  Register file ports logic
  =====================================================
*/
assign read_addr1_i   = instr_i[19:15];
assign read_addr2_i   = instr_i[24:20];
assign write_addr_i   = instr_i[11:07];
assign write_enable_i = gpr_we_o & !(stall_i | trap);

always_comb begin
  priority case(wb_sel_o)
    WB_EX_RESULT: write_data_i = result_o;
    WB_LSU_DATA : write_data_i = mem_rd_i;
    WB_CSR_DATA : write_data_i = csr_wd;
  endcase
end
//=====================================================



/*
  =====================================================
  Modules instantiation
  =====================================================
*/
logic mem_we, mem_req;
register_file rf (.*);
decoder decoder(.*, .fetched_instr_i(instr_i), .mem_we_o(mem_we), .mem_req_o(mem_req));
alu alu (.*);
csr_controller csr(
  .*,
  .addr_i(instr_i[31:20]),
  .pc_i(PC),
  .mcause_i(mcause),
  .rs1_data_i(read_data1_o),
  .imm_data_i(imm_Z),
  .read_data_o(csr_wd),
  .write_enable_i(csr_we_o),
  .trap_i(trap),
  .opcode_i(csr_op_o)
);
interrupt_controller irq_ctrl(
  .*,
  .exception_i(illegal_instr_o),
  .mie_i(mie_o[16]),
  .mret_i(mret_o)
);
//=====================================================



/*
  =====================================================
  Inmodule logic
  =====================================================
*/
assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};
assign imm_U = {instr_i[31:12], 12'h0};
assign imm_S = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
assign imm_B = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
assign imm_J = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
assign imm_Z = {{27{instr_i[19]}}, instr_i[19:15]};


assign jalr_sum   = read_data1_o + imm_I;

always_comb begin
  unique case(1'b1)
    jal_o             : pc_add = imm_J;
    branch_o & flag_o : pc_add = imm_B;
    default           : pc_add = 32'd4;
  endcase
end



assign not_a_stall  = !stall_i;
assign trap         = irq_o | illegal_instr_o;
assign mcause       = illegal_instr_o ? 32'h0000_0002 : irq_cause_o;

always_ff @(posedge clk_i or posedge rst_i) begin
  if(rst_i) begin
    PC <= 32'd0;
  end
  else begin
    if(not_a_stall | trap) begin
      if(mret_o) begin
        PC <= mepc_o;
      end
      else if(trap) begin
        PC <= mtvec_o;
      end
      else if(jalr_o) begin
        PC <= {jalr_sum[31:1], 1'b0};
      end
      else begin
        PC <= PC + pc_add;
      end
    end
    else begin
      PC <= PC;
    end
  end
end

assign mem_addr_o   = result_o;
assign instr_addr_o = PC;
assign mem_wd_o     = read_data2_o;
assign mem_we_o     = mem_we & !trap;
assign mem_req_o    = mem_req & !trap;
assign trap_o       = trap;
//=====================================================

endmodule
