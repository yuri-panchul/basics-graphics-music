/*******************************************************************************************/
/**                                                                                       **/
/** Copyright 2021 Monte J. Dalrymple                                                     **/
/**                                                                                       **/
/** SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1                                      **/
/**                                                                                       **/
/** Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use  **/
/** this file except in compliance with the License, or, at your option, the Apache       **/
/** License version 2.0. You may obtain a copy of the License at                          **/
/**                                                                                       **/
/** https://solderpad.org/licenses/SHL-2.1/                                               **/
/**                                                                                       **/
/** Unless required by applicable law or agreed to in writing, any work distributed under **/
/** the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF   **/
/** ANY KIND, either express or implied. See the License for the specific language        **/
/** governing permissions and limitations under the License.                              **/
/**                                                                                       **/
/** YRV cpu                                                           Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module yrv_cpu (csr_achk, csr_addr, csr_read, csr_wdata, csr_write, dbg_type, debug_mode,
                dpc_reg, ebrk_inst, eret_inst, iack_int, iack_nmi, inst_ret, mcause_reg,
                mem_addr, mem_ble, mem_lock, mem_trans, mem_wdata, mem_write, mepc_reg,
                nmip_reg, wfi_state, brk_req, bus_32, clk, csr_idata, csr_rdata, csr_ok_ext,
                csr_ok_int, dbg_req, ebrkd_reg, halt_reg, irq_bus, mem_rdata, mem_ready,
                mli_code, mtvec_reg, resetb, step_reg, vmode_reg);

  input         brk_req;                                   /* breakpoint request           */
  input         bus_32;                                    /* 32-bit bus select            */
  input         clk;                                       /* cpu clock                    */
  input         csr_ok_ext;                                /* valid external csr addr      */
  input         csr_ok_int;                                /* valid internal csr addr      */
  input         dbg_req;                                   /* debug request                */
  input         ebrkd_reg;                                 /* ebreak causes debug          */
  input         halt_reg;                                  /* halt (enter debug)           */
  input         resetb;                                    /* master reset                 */
  input         mem_ready;                                 /* memory ready                 */
  input         step_reg;                                  /* single-step                  */
  input   [1:0] vmode_reg;                                 /* vectored interrupt mode      */
  input   [4:0] irq_bus;                                   /* irq: nmi/li/ei/tmr/sw        */
  input   [6:0] mli_code;                                  /* mli highest pending          */
  input  [31:0] csr_idata;                                 /* csr internal read data       */
  input  [31:0] csr_rdata;                                 /* csr external read data       */
  input  [31:0] mem_rdata;                                 /* memory read data             */
  input  [31:2] mtvec_reg;                                 /* trap vector base             */

  output        csr_read;                                  /* csr read enable              */
  output        csr_write;                                 /* csr write enable             */
  output        debug_mode;                                /* in debug mode                */
  output        ebrk_inst;                                 /* ebreak instruction           */
  output        eret_inst;                                 /* eret instruction             */
  output        iack_int;                                  /* iack: nmi/li/ei/tmr/sw       */
  output        iack_nmi;                                  /* iack: nmi                    */
  output        inst_ret;                                  /* inst retired                 */
  output        mem_lock;                                  /* memory lock (rmw)            */
  output        mem_write;                                 /* memory write enable          */
  output        nmip_reg;                                  /* nmi pending in debug mode    */
  output        wfi_state;                                 /* waiting for interrupt        */
  output  [1:0] mem_trans;                                 /* memory transfer type         */
  output  [2:0] dbg_type;                                  /* debug cause                  */
  output  [3:0] mem_ble;                                   /* memory byte lane enables     */
  output  [6:0] mcause_reg;                                /* exception cause              */
  output [11:0] csr_achk;                                  /* csr address to check         */
  output [11:0] csr_addr;                                  /* csr address                  */
  output [31:0] csr_wdata;                                 /* csr write data               */
  output [31:1] dpc_reg;                                   /* debug pc                     */
  output [31:0] mem_addr;                                  /* memory address               */
  output [31:0] mem_wdata;                                 /* memory write data            */
  output [31:1] mepc_reg;                                  /* exception pc                 */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          amo_4_dec;                                 /* amo inst decode              */
  wire          aop_4_add,   aop_4_and,    aop_4_or;       /* alu operation selects        */
  wire          aop_4_pack,  aop_4_rol,    aop_4_ror;
  wire          aop_4_shfl,  aop_4_sl,     aop_4_sr;
  wire          aop_4_xor;
  wire          bits_4_dec;                                /* bit op inst decode           */
  wire          br_4_dec;                                  /* br inst decode               */
  wire          br_5_cyout;                                /* br test carry out            */
  wire          br_5_ge,     br_5_ne,      br_5_uge;       /* br test ge/ne/uge            */
  wire          br_5_true;                                 /* br test result               */
  wire          csr_4_dec;                                 /* csr instruction              */
  wire          csr_4_ok;                                  /* csr addr ok                  */
  wire          dpc_wr,      mcause_wr,    mepc_wr;        /* csr reg wr strobes           */
  wire          dbg_4_out;                                 /* final debug request          */
  wire          dret_4_dec;                                /* dret instruction             */
  wire          ebrk_4_dec;                                /* ebreak instruction           */
  wire          ecall_4_dec;                               /* ecall instruction            */
  wire          eret_4_dec;                                /* eret instruction             */
  wire          exc_5_req;                                 /* exception                    */
  wire          except_wr;                                 /* exception wr                 */
  wire          fn3_4_0,     fn3_4_1,      fn3_4_2;        /* fn3 decodes                  */
  wire          fn3_4_3,     fn3_4_4,      fn3_4_5;
  wire          fn3_4_6,     fn3_4_7;
  wire          fn5_4_04,    fn5_4_05,     fn5_4_07;       /* fn5 decodes                  */
  wire          fn5_4_0f,    fn5_4_18,     fn5_4_1f;
  wire          fn7_4_00,    fn7_4_04,     fn7_4_10;       /* fn7 decodes                  */
  wire          fn7_4_14,    fn7_4_20,     fn7_4_24;
  wire          fn7_4_30,    fn7_4_34;
  wire          fn7_4_00x,   fn7_4_04x,    fn7_4_10x;      /* fn7 amo decodes              */
  wire          fn7_4_20x,   fn7_4_30x;
  wire          fnc_4_dec;                                 /* fence instruction            */
  wire          flush_5_exc;                               /* invalidate stage 6           */
  wire          imm6_nz,     imm8_nz;                      /* rv32c non-zero imm field     */
  wire          inst_5_ret,  inst_ret;                     /* inst retired                 */
  wire          invb_4_dec;                                /* b invert inst decode         */
  wire          ld_4_dec;                                  /* ld inst decode               */
  wire          ld_addr;                                   /* load addr for ld/st          */
  wire          ld_insth,    ld_instl;                     /* load inst_reg                */
  wire          ld_pc;                                     /* load pc                      */
  wire          ld_rmw;                                    /* start write part of rmw      */
  wire          ls_run;                                    /* ld/st running                */
  wire          mem_lock;                                  /* memory lock (rmw)            */
  wire          mem_rdy,     mem_rdy_v;                    /* masked mem_ready             */
  wire          mem_write;                                 /* memory write enable          */
  wire          opc_4_aui,   opc_4_br,     opc_4_fnc;      /* major opcode decodes         */
  wire          opc_4_imm,   opc_4_jal,    opc_4_jalr;
  wire          opc_4_ld,    opc_4_lui,    opc_4_op;
  wire          opc_4_st,    opc_4_sys,    opc_4_amo;
  wire          rr_4_zer;                                  /* rd/rs1 both zero             */
  wire          rd_n2,       rd_nz;                        /* rv32c special rd field       */
  wire          rs2_nz;                                    /* rv32c non-zero rs2 field     */
  wire          run_mem,     run_dec,      run_exe;        /* pipeline enables             */
  wire          sbext_4_dec;                               /* sbext inst decode            */
  wire          sext1_07,    sext1_15;                     /* din sign extend              */
  wire          sext1_23,    sext1_31;
  wire          shftd_4_dec;                               /* shamt reg decode             */
  wire          shfti_4_dec;                               /* shamt imm decode             */
  wire          src1_4_byp,  src2_4_byp;                   /* stage 4 reg bypass           */
  wire          src1_5_byp,  src2_5_byp;                   /* stage 5 reg bypass           */
  wire          shft_5_inp;                                /* shift left/right input       */
  wire          slt_4_dec;                                 /* slt inst decode              */
  wire          sltu_4_dec;                                /* sltu inst decode             */
  wire          st_4_dec;                                  /* st decode                    */
  wire          st_out;                                    /* ld/st store                  */
  wire          stall_align;                               /* stall for unaligned          */
  wire          stall_cmp;                                 /* stall for compressed         */
  wire          stall_csr;                                 /* stall for csr                */
  wire          stall_ldst;                                /* stall for ld/st              */
  wire          strt_5_csr;                                /* start csr access             */
  wire          vecti_5_req;                               /* vectored interrupt request   */
  wire          wfi_4_dec;                                 /* wfi instruction              */
  wire          word_inst,   word_instu;                   /* word instruction             */
  wire          wr_6_en;                                   /* reg write enable             */
  wire          wreg_4_out;                                /* reg write enable             */
  wire    [1:0] mem_trans;                                 /* memory transfer type         */
  wire    [2:0] pc_1_adj;                                  /* adjustment for next pc       */
  wire    [2:0] type_out;                                  /* ld/st width                  */
  wire    [3:0] mem_ble;                                   /* mem byte lane enables        */
  wire    [4:0] c_rd,        c_rdp;                        /* rv32c rd field               */
  wire    [4:0] c_rs1,       c_rs1p;                       /* rv32c rs1 field              */
  wire    [4:0] c_rs2,       c_rs2p;                       /* rv32c rs2 field              */
  wire    [4:0] rd_3_addr;                                 /* rd address                   */
  wire    [4:0] rs1_3_addr,  rs2_3_addr;                   /* rs1/rs2 address              */
  wire    [4:0] shamt_5_out, shamt_5_cmp;                  /* shift amount, complement     */
  wire    [4:0] slamt_5_out, sramt_5_out;                  /* final sl/sr amount           */
  wire    [6:0] mcause_irq;                                /* interrupt cause              */
  wire    [7:0] opc_3_out;                                 /* reduced opcode               */
  wire    [7:0] src1_5_rv0,  src1_5_rv1;                   /* bit-revered bytes            */
  wire    [7:0] src1_5_rv2,  src1_5_rv3;
  wire   [11:0] csr_achk;                                  /* csr address to check         */
  wire   [11:0] csr_addr;                                  /* csr address                  */
  wire   [31:0] addr_out;                                  /* exception/ld/st address      */
  wire   [31:0] alu_5_add;                                 /* alu add/sub input            */
  wire   [31:0] alu_5_ain,   alu_5_bin;                    /* alu a/b inputs               */
  wire   [31:0] alu_5_bim;                                 /* alu b intermediate input     */
  wire   [31:0] alu_5_ext;                                 /* alu external input           */
  wire   [31:0] alu_5_tst;                                 /* alu b test input             */
  wire   [31:0] dst_6_data;                                /* reg write data               */
  wire   [31:2] inst;                                      /* instruction to execute       */
  wire   [31:0] ls_addr_nxt;                               /* ld/st next address           */
  wire   [31:0] ls_amo_add;                                /* amo add output               */
  wire   [31:0] mem_addr;                                  /* memory address               */
  wire   [31:0] mem_idata;                                 /* memory ifetch data           */
  wire   [31:0] mtvec_addr;                                /* mtvec address                */
  wire   [31:0] opc;                                       /* opcode                       */
  wire   [31:0] pc_1_nxt,    pc_3_nxt;                     /* next pc                      */
  wire   [31:0] rot_5_out;                                 /* rotate gated out             */
  wire   [31:0] shfl_5_out,  pack_5_out;                   /* shuffle/pack gated out       */
  wire   [31:0] sl_5_out,    sr_5_out;                     /* shift left/right gated out   */
  wire   [31:0] src1_4_out,  src1_5_out;                   /* rs1 data                     */
  wire   [31:0] src2_4_out,  src2_5_out;                   /* rs2 data                     */

  reg           a_add_5_reg, a_ain_5_reg, a_and_5_reg;     /* alu function selects         */
  reg           a_bin_5_reg, a_ext_5_reg, a_or_5_reg;
  reg           a_tst_5_reg, a_xor_5_reg;
  reg           alta_5_reg,  altb_5_reg;                   /* alu alt in select            */
  reg           amo_5_reg,   amo_6_reg;                    /* amoxxx instruction           */
  reg           bits_5_reg;                                /* alt bin (bit sel)            */
  reg           brk_int;                                   /* sampled brk_req              */
  reg           csr_read,    csr_write;                    /* csr strobes                  */
  reg           dbg_int;                                   /* sampled dbg_req              */
  reg           debug_mode;                                /* in debug mode                */
  reg           dret_5_reg;                                /* dret instruction             */
  reg           ebrk_5_reg;                                /* ebreak instruction           */
  reg           ebrk_inst;                                 /* ebreak instruction output    */
  reg           ecall_5_reg;                               /* ecall instruction            */
  reg           eret_5_reg;                                /* eret instruction             */
  reg           eret_inst;                                 /* eret instruction output      */
  reg           flush_5_reg;                               /* pipeline flush               */
  reg           iack_int;                                  /* iack: int/li/ei/tmr/sw       */
  reg           iack_nmi;                                  /* iack: nmi                    */
  reg           invb_5_reg;                                /* invert bin                   */
  reg           jal_5_reg,   jal_6_reg;                    /* jal instruction              */
  reg           ld_5_reg,    ld_6_reg;                     /* ld instruction               */
  reg           ldpc_1_reg,  ldpc_2_reg;                   /* load pc                      */
  reg           ls_amo_reg;                                /* amo store op                 */
  reg           ls_st_reg;                                 /* ld/st/amo store op           */
  reg           mem32_reg;                                 /* latched 32-bit info          */
  reg           nmi_5_reg;                                 /* nmi pending                  */
  reg           nmip_reg;                                  /* nmi pending in debug mode    */
  reg           pack_5_reg;                                /* pack inst                    */
  reg           rdymask_reg;                               /* mem_ready mask               */
  reg           retire_6_reg;                              /* retire instruction           */
  reg           rol_5_reg;                                 /* rol inst                     */
  reg           ror_5_reg;                                 /* ror inst                     */
  reg           rs1by_4_reg, rs2by_4_reg;                  /* rs1/2 bypass       (stage 3) */
  reg           rs1z_4_reg,  rs2z_4_reg;                   /* rs1/2 addr zero              */
  reg           rs1nz_6_reg;                               /* rs1 addr not zero            */
  reg           s4byp1_reg,  s5byp1_reg;                   /* src1 bypass      (stage 4/5) */
  reg           s4byp2_reg,  s5byp2_reg;                   /* src2 bypass      (stage 4/5) */
  reg           sbext_5_reg;                               /* sbext inst                   */
  reg           shfl_5_reg;                                /* rev/sext inst                */
  reg           shftd_5_reg;                               /* shamt reg                    */
  reg           shfti_5_reg;                               /* shamt imm                    */
  reg           sl_5_reg;                                  /* sl/slo inst                  */
  reg           slt_5_reg;                                 /* slt inst                     */
  reg           sltu_5_reg;                                /* sltu inst                    */
  reg           sr_5_reg;                                  /* sra/srl/sro inst             */
  reg           ss_reg;                                    /* single-step request          */
  reg           st_5_reg;                                  /* st instruction               */
  reg           trap_5_reg;                                /* bad inst trap                */
  reg           valid_0_reg, valid_1_reg, valid_2_reg;     /* state valid                  */
  reg           valid_3_reg, valid_4_reg, valid_5_reg;
  reg           valid_6_reg;
  reg           wfi_5_reg;                                 /* wfi instruction              */
  reg           wfi_reg,     wfi_state;                    /* waiting for interrupt        */
  reg           wreg_5_reg,  wreg_6_reg;                   /* reg write enable             */
  reg     [1:0] ls_ainc_ini, ls_ainc_reg;                  /* ld/st addr incr              */
  reg     [1:0] ls_sinc_reg;                               /* stored ld/st addr incr       */
  reg     [1:0] pc_3_inc;                                  /* pc_3 increment value         */
  reg     [2:0] dbg_5_reg;                                 /* dbg src                      */
  reg     [2:0] dbg_type;                                  /* debug cause                  */
  reg     [2:0] ifull_3_nxt, ifull_3_reg;                  /* inst reg tracker             */
  reg     [2:0] ls_type_reg;                               /* ld/st type                   */
  reg     [2:0] runcsr_reg;                                /* csr r/w tracker              */
  reg     [3:0] ls_ble_out;                                /* ld/st byte lane enables      */
  reg     [3:0] ls_ph_ini,   ls_ph_reg;                    /* ld/st phase track            */
  reg     [3:0] ls_sph_reg;                                /* stored ld/st phase track     */
  reg     [4:0] csrop_5_reg, csrop_6_reg;                  /* csr ctrl imm/rw/rc/rs        */
  reg     [4:0] rd_4_reg,    rd_5_reg,    rd_6_reg;        /* rd address                   */
  reg     [4:0] rs1_4_reg,   rs1_5_reg;                    /* rs1 address                  */
  reg     [4:0] rs2_4_reg;                                 /* rs2 address                  */
  reg     [5:0] br_5_reg;                                  /* br instruction               */
  reg     [5:0] irq_5_reg;                                 /* irq dbg/nmi/li/ei/tmr/sw     */
  reg     [6:0] mli_5_reg;                                 /* mli highest pending          */
  reg     [7:0] byte_5_sel;                                /* byte-wide bit select         */
  reg     [7:0] ls_din3_reg;                               /* ld/st read data              */
  reg     [7:0] opc_4_reg;                                 /* reduced opcode               */
  reg     [7:5] opc_5_reg;                                 /* bits 7:5 of opocde           */
  reg     [7:0] rdelay_reg;                                /* startup delay                */
  reg     [6:0] mcause_reg;                                /* exception cause              */
  reg    [11:0] imm_6_reg;                                 /* csr addr                     */
  reg    [15:0] instu_3_reg;                               /* unaligned inst reg           */
  reg    [31:0] alu_5_out,   alu_6_reg;                    /* alu output                   */
  reg    [31:0] bit_5_sel;                                 /* bit select                   */
  reg    [31:0] csr_wdata;                                 /* csr write data               */
  reg    [31:0] csrdat_reg;                                /* csr read data                */
  reg    [31:0] csrmod_6_reg;                              /* csr modifier data            */
  reg    [31:1] dpc_reg;                                   /* debug pc                     */
  reg    [31:0] dst_6d_data;                               /* latched write data           */
  reg    [31:2] e_c0,        e_c1,        e_c2;            /* expanded opcodes             */
  reg    [31:0] imm_3_out,   imm_4_reg,   imm_5_reg;       /* immediate data               */
  reg    [31:0] inst_3_reg;                                /* inst reg                     */
  reg    [31:0] ls_addr_reg;                               /* active ls address            */
  reg    [31:0] ls_amo_out;                                /* amo alu output               */
  reg    [31:0] ls_data_out, ls_data_reg;                  /* ld/st write data             */
  reg    [31:0] ls_din1_reg, ls_din2_reg;                  /* ld/st read data              */
  reg    [31:0] ls_sadd_reg;                               /* stored ls address            */
  reg    [31:0] mem_rdat;                                  /* memory read data             */
  reg    [31:0] mem_wdata;                                 /* memory write data            */
  reg    [31:1] mepc_reg;                                  /* exception pc                 */
  reg    [31:0] pack_5_mux;                                /* pack data                    */
  reg    [31:1] pc_1_reg,    pc_2_reg,    pc_3_reg;        /* program counter              */
  reg    [31:1] pc_4_reg,    pc_5_reg;
  reg    [31:0] rdata_reg;                                 /* latched mem_rdata            */
  reg    [31:0] shfl_5_mux;                                /* shuffle data                 */
  reg    [31:0] sl_5_mux,    sr_5_mux;                     /* shft left/right mux out      */
  reg    [31:0] src1_5_reg,  src2_5_reg;                   /* rs1/rs2 data                 */

`ifdef INSTANCE_REG
  wire   [31:0] src1_4_rdata, src2_4_rdata;                /* raw read data                */
`else
  reg    [31:0] regf_mem [0:31];                           /* reg file ram                 */
  reg    [31:0] src1_4_rdata, src2_4_rdata;                /* raw read data                */
`endif

`ifdef INSTANCE_SUB
  wire   [31:0] op_5_diff;                                 /* operand diff                 */
`else
  wire   [32:0] op_5_diff;                                 /* operand diff                 */
`endif

  /*****************************************************************************************/
  /* start-up and pipeline control                                                         */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      mem32_reg   <=  1'b0;
      rdata_reg   <= 32'h0;
      rdelay_reg  <=  8'h0;
      rdymask_reg <=  1'b0;
      valid_0_reg <=  1'b0;
      valid_1_reg <=  1'b0;
      end
    else begin
      if (!rdelay_reg[7]) mem32_reg <= bus_32;
      if (valid_0_reg && mem_rdy) rdata_reg <= mem_rdata;
      rdelay_reg  <= rdelay_reg + !rdelay_reg[7];
      rdymask_reg <= ~|mem_trans && mem_ready;
      if (mem_rdy) valid_0_reg <= !mem_trans[1] && mem_trans[0];
      valid_1_reg <= rdelay_reg[7] || valid_1_reg;
      end
    end

  assign mem_idata = (valid_0_reg) ? mem_rdata : rdata_reg;
  assign mem_rdy   = mem_ready || rdymask_reg;
  assign mem_rdy_v = mem_rdy && valid_1_reg;

  assign run_dec   = mem_rdy_v && !stall_csr && !stall_ldst; 
  assign run_exe   = mem_rdy_v && !stall_csr && !stall_ldst && !stall_align; 
  assign run_mem   = mem_rdy_v && !stall_csr && !stall_ldst && (ld_pc || !stall_cmp); 

  /*****************************************************************************************/
  /* clock 1 - memory address                                                              */
  /*****************************************************************************************/
  assign pc_1_adj = {(!wfi_reg && mem32_reg), (!wfi_reg && !mem32_reg), 1'b0};

`ifdef INSTANCE_INC
  inst_inc  PC_1_INC  ( .inc_out(pc_1_nxt), .clk(clk), .inc_ain({pc_1_reg, 1'b0}),
                        .inc_bin(pc_1_adj) ); 
`else
  assign pc_1_nxt = {pc_1_reg, 1'b0} + pc_1_adj;
`endif

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      ldpc_1_reg <=  1'b0;
      pc_1_reg   <= `RST_BASE;
      end
    else if (run_mem) begin
      ldpc_1_reg <=  ld_pc;
      pc_1_reg   <= (ld_pc)     ? addr_out[31:1] :
                    (mem32_reg) ? {pc_1_nxt[31:2], 1'b0} : pc_1_nxt[31:1];
      end
    end

  /*****************************************************************************************/
  /* load/store/amo state machine                                                          */
  /*****************************************************************************************/
  always @ (mem32_reg or addr_out or type_out) begin
    casex ({mem32_reg, type_out[1:0], addr_out[1:0]})
      5'b001x1,
      5'b01xx0,
      5'b10111,
      5'b11x01,
      5'b11x1x: ls_ph_ini = 4'b0111;
      5'b01xx1: ls_ph_ini = 4'b1111;
      default:  ls_ph_ini = 4'b0011;
      endcase
    end

  always @ (addr_out or type_out) begin
    case ({type_out[1:0], addr_out[0]})
      3'b100:  ls_ainc_ini = 2'h2;
      default: ls_ainc_ini = 2'h1;
      endcase
    end

`ifdef INSTANCE_INC
  inst_inc LS_ADDR_INC ( .inc_out(ls_addr_nxt), .clk(clk), .inc_ain(ls_addr_reg),
                         .inc_bin({1'b0, ls_ainc_reg}) ); 
`else
  assign ls_addr_nxt = ls_addr_reg + ls_ainc_reg;
`endif

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      ls_addr_reg <= 32'h0;
      ls_ainc_reg <=  2'h2;
      ls_ph_reg   <=  4'h0;
      ls_sadd_reg <= 32'h0;
      ls_sinc_reg <=  2'h0;
      ls_sph_reg  <=  4'h0;
      ls_data_reg <= 32'h0;
      ls_type_reg <=  3'h2;
      ls_amo_reg  <=  1'b0;
      ls_st_reg   <=  1'b0;
      end
    else begin
      if ((ld_addr || stall_ldst) && mem_rdy_v) begin
        ls_addr_reg <= (ld_addr) ? addr_out    :
                       (ld_rmw)  ? ls_sadd_reg : ls_addr_nxt;
        ls_ainc_reg <= (ld_addr) ? ls_ainc_ini :
                       (ld_rmw)  ? ls_sinc_reg : 2'h2;
        ls_ph_reg   <= (ld_addr) ? ls_ph_ini   :
                       (ld_rmw)  ? ls_sph_reg  :
                                   {1'b0, ls_ph_reg[3:2], (|ls_ph_reg[3:2] ||
                                    (ls_ph_reg[1] && !ls_st_reg))};
        end
      if (ld_addr && mem_rdy_v) begin
        ls_data_reg <= src2_5_out;
        ls_sadd_reg <= addr_out;
        ls_sinc_reg <= ls_ainc_ini;
        ls_sph_reg  <= ls_ph_ini;
        ls_type_reg <= type_out;
        end
      if ((ld_addr || ld_rmw) && mem_rdy_v) begin
        ls_amo_reg  <= ld_rmw;
        ls_st_reg   <= ld_rmw || st_out;
        end
      end
    end

  assign ld_rmw     = !ls_st_reg && amo_6_reg && (ls_ph_reg == 4'h1);
  assign ls_run     = |ls_ph_reg[3:1];
  assign stall_ldst = |ls_ph_reg;

  /*****************************************************************************************/
  /* dedicated amo alu                                                                     */
  /*****************************************************************************************/
`ifdef INSTANCE_ADD
  inst_add AMO_ADD   ( .add_out(ls_amo_add), .clk(clk), .add_ain(ls_data_reg),
                       .add_bin(mem_rdat), .add_cyin(1'b0) ); 
`else
  assign ls_amo_add = ls_data_reg + mem_rdat;
`endif

  always @ (imm_6_reg or ls_amo_add or ls_amo_reg or ls_data_reg or mem_rdat) begin
    case ({ls_amo_reg, imm_6_reg[11:7]})
      6'b100000: ls_amo_out = ls_amo_add;
      6'b100100: ls_amo_out = ls_data_reg ^ mem_rdat;
      6'b101000: ls_amo_out = ls_data_reg | mem_rdat;
      6'b101100: ls_amo_out = ls_data_reg & mem_rdat;
      default:   ls_amo_out = ls_data_reg;
      endcase
    end

  /*****************************************************************************************/
  /* write data multiplexing                                                               */
  /*****************************************************************************************/
  always @ (mem32_reg or ls_amo_out or ls_type_reg or ls_sadd_reg or ls_ph_reg) begin
    casex ({mem32_reg, ls_type_reg[1:0], ls_sadd_reg[1:0], ls_ph_reg[3:2]})
      7'b000x1xx,
      7'b001x101,
      7'b010x111,
      7'b010x100,
      7'b1xx01xx: ls_data_out = {ls_amo_out[23:0], ls_amo_out[31:24]};
      7'b010x000,
      7'b1xx10xx: ls_data_out = {ls_amo_out[15:0], ls_amo_out[31:16]};
      7'b001x100,
      7'b010x101,
      7'b1xx11xx: ls_data_out = {ls_amo_out[7:0],  ls_amo_out[31:8]};
      default:    ls_data_out =  ls_amo_out;
      endcase
    end

  always @ (mem32_reg or ls_type_reg or ls_sadd_reg or ls_ph_reg) begin
    casex ({mem32_reg, ls_type_reg[1:0], ls_sadd_reg[1:0], ls_ph_reg[3:2]})
      7'b000x0xx,
      7'b001x100,
      7'b010x100,
      7'b10000xx,
      7'b1011100,
      7'b1100100: ls_ble_out = 4'b0001;
      7'b01xxx11,
      7'b001xxx1,
      7'b000x1xx,
      7'b10001xx: ls_ble_out = 4'b0010;
      7'b10010xx: ls_ble_out = 4'b0100;
      7'b10101xx: ls_ble_out = 4'b0110;
      7'b11x1100: ls_ble_out = 4'b0111;
      7'b10011xx,
      7'b10111x1,
      7'b11x11x1: ls_ble_out = 4'b1000;
      7'b10110xx,
      7'b11x10x1: ls_ble_out = 4'b1100;
      7'b11x01x1: ls_ble_out = 4'b1110;
      7'b11x00xx: ls_ble_out = 4'b1111;
      default:    ls_ble_out = 4'b0011;
      endcase
    end

  /*****************************************************************************************/
  /* memory interface                                                                      */
  /*****************************************************************************************/
  assign mem_addr  = (stall_ldst) ? ls_addr_reg      :
                     (stall_cmp)  ? {pc_2_reg, 1'b0} : {pc_1_reg, 1'b0};
  assign mem_lock  = stall_ldst && amo_6_reg;
  assign mem_ble   = (ls_run) ? ls_ble_out : {mem32_reg, mem32_reg, 2'b11};
  assign mem_trans = {ls_run, ls_run || !(!valid_1_reg || stall_csr || ld_pc || wfi_state ||
                                (!ls_ph_reg[1] && ls_ph_reg[0]))};
  assign mem_write =  ls_run && ls_st_reg;

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      mem_wdata <= 32'h0;
      end
    else begin
      if (mem_rdy_v && ls_st_reg && ls_ph_reg[1]) mem_wdata <= ls_data_out;
      end
    end

  /*****************************************************************************************/
  /* read data assembly                                                                    */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      ls_din3_reg <=  8'h0;
      ls_din2_reg <= 32'h0;
      ls_din1_reg <= 32'h0;
      end
    else begin
      if (mem_rdy_v && !ls_st_reg && ls_ph_reg[2]) ls_din3_reg <= mem_rdata[15:8];
      if (mem_rdy_v && !ls_st_reg && ls_ph_reg[1]) ls_din2_reg <= mem_rdata;
      if (mem_rdy_v && !ls_st_reg && ls_ph_reg[0]) ls_din1_reg <= mem_rdata;
      end
    end

  assign sext1_07 = !ls_type_reg[2] && ls_din1_reg[7];
  assign sext1_15 = !ls_type_reg[2] && ls_din1_reg[15];
  assign sext1_23 = !ls_type_reg[2] && ls_din1_reg[23];
  assign sext1_31 = !ls_type_reg[2] && ls_din1_reg[31];

  always @ (mem32_reg or ls_type_reg or ls_sadd_reg or ls_din3_reg or ls_din2_reg or
            ls_din1_reg or sext1_07 or sext1_15 or sext1_23 or sext1_31) begin
    casex ({mem32_reg, ls_type_reg[1:0], ls_sadd_reg[1:0]})
      5'b00010,
      5'bx0000: mem_rdat = { {24{sext1_07}},   ls_din1_reg[7:0]  };
      5'b00011,
      5'bx0001: mem_rdat = { {24{sext1_15}},   ls_din1_reg[15:8] };
      5'b00110,
      5'bx0100: mem_rdat = { {16{sext1_15}},   ls_din1_reg[15:0] };
      5'b001x1: mem_rdat = { {16{sext1_07}},   ls_din1_reg[7:0],   ls_din2_reg[15:8] };
      5'b010x0: mem_rdat = {ls_din1_reg[15:0], ls_din2_reg[15:0] };
      5'b010x1: mem_rdat = {ls_din1_reg[7:0],  ls_din2_reg[15:0],  ls_din3_reg};
      5'b10010: mem_rdat = { {24{sext1_23}},   ls_din1_reg[23:16]};
      5'b10011: mem_rdat = { {24{sext1_31}},   ls_din1_reg[31:24]};
      5'b10101: mem_rdat = { {16{sext1_23}},   ls_din1_reg[23:8] };
      5'b10110: mem_rdat = { {16{sext1_31}},   ls_din1_reg[31:16]};
      5'b10111: mem_rdat = { {16{sext1_07}},   ls_din1_reg[7:0],   ls_din2_reg[31:24]};
      5'b11001: mem_rdat = {ls_din1_reg[7:0],  ls_din2_reg[31:8] };
      5'b11010: mem_rdat = {ls_din1_reg[15:0], ls_din2_reg[31:16]};
      5'b11011: mem_rdat = {ls_din1_reg[23:0], ls_din2_reg[31:24]};
      default:  mem_rdat =  ls_din1_reg;
      endcase
    end

  /*****************************************************************************************/
  /* clock 2 - memory access                                                               */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      ldpc_2_reg  <=  1'b0;
      pc_2_reg    <= `RST_BASE;
      valid_2_reg <=  1'b0;
      end
    else if (run_mem) begin
      ldpc_2_reg  <= ldpc_1_reg;
      pc_2_reg    <= pc_1_reg;
      valid_2_reg <= !ld_pc && !wfi_reg && valid_1_reg;
      end
    end

  /*****************************************************************************************/
  /* clock 3 - pre-decode                                                                  */
  /*****************************************************************************************/
  assign ld_insth = mem32_reg || ( word_inst && (ifull_3_reg == 3'b001));
  assign ld_instl = mem32_reg || (!word_inst && (ifull_3_reg == 3'b001)) ||
                    (ifull_3_reg == 3'b011) || (ifull_3_reg == 3'b000);

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      ifull_3_reg <=  3'h0;
      inst_3_reg  <= 32'h0;
      instu_3_reg <= 16'h0;
      end
    else if (run_dec) begin
      ifull_3_reg <= (valid_2_reg && !ldpc_1_reg) ? ifull_3_nxt : 3'b000;
      if (ld_insth) inst_3_reg[31:16] <= (mem32_reg) ? mem_idata[31:16] : mem_idata[15:0];
      if (ld_instl) inst_3_reg[15:0]  <= mem_idata[15:0];
      instu_3_reg <= inst_3_reg[31:16];
      end
    end

  assign stall_align = valid_3_reg && ((word_instu && (ifull_3_reg == 3'b010)) ||
                                       (word_inst  && (ifull_3_reg == 3'b001)));
  assign word_instu  = &inst_3_reg[17:16];
  assign word_inst   = &inst_3_reg[1:0];
  assign stall_cmp   = ((ifull_3_reg == 3'b011) && !word_instu && !word_inst) ||
                       ((ifull_3_reg == 3'b111) && !word_instu);

  always @ (mem32_reg or ifull_3_reg or pc_2_reg or word_inst or word_instu) begin
    case ({mem32_reg, ifull_3_reg})
      4'b0000: ifull_3_nxt = 3'b001;
      4'b0001: ifull_3_nxt = (word_inst)  ? 3'b011 : 3'b001;
      4'b0011: ifull_3_nxt = 3'b001;
      4'b1000: ifull_3_nxt = {2'b01, !pc_2_reg[1]};
      4'b1010: ifull_3_nxt = (word_instu) ? 3'b111 : 3'b011;
      4'b1011: ifull_3_nxt = (word_inst)  ? 3'b011 :
                             (word_instu) ? 3'b111 : 3'b100;
      4'b1100: ifull_3_nxt = 3'b011;
      4'b1111: ifull_3_nxt = (word_instu) ? 3'b111 : 3'b100;
      default: ifull_3_nxt = 3'b000;
      endcase
    end

  assign opc[31:16] = (ifull_3_reg[2]) ? inst_3_reg[15:0] : inst_3_reg[31:16];
  assign opc[15:0]  = (ifull_3_reg[2]) ? instu_3_reg :
                      (ifull_3_reg[0]) ? inst_3_reg[15:0] : inst_3_reg[31:16];

  /*****************************************************************************************/
  /* stage 3 program counter                                                               */
  /*****************************************************************************************/
  always @ (ifull_3_reg or word_inst) begin
    case (ifull_3_reg)
      3'b011:  pc_3_inc = {word_inst, !word_inst};
      3'b111:  pc_3_inc = 2'b10;
      default: pc_3_inc = 2'b01;
      endcase
    end

`ifdef INSTANCE_INC
  inst_inc  PC_3_INC  ( .inc_out(pc_3_nxt), .clk(clk), .inc_ain({pc_3_reg, 1'b0}),
                        .inc_bin({pc_3_inc, 1'b0}) ); 
`else
  assign pc_3_nxt = {pc_3_reg, 1'b0} + {pc_3_inc, 1'b0};
`endif

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      pc_3_reg    <= `RST_BASE;
      valid_3_reg <=  1'b0;
      end
    else if (run_exe) begin
      pc_3_reg    <= (valid_3_reg) ? pc_3_nxt[31:1] : pc_2_reg;
      valid_3_reg <= !ld_pc && valid_2_reg;
      end
    end

  /*****************************************************************************************/
  /* compressed opcode common                                                              */
  /*****************************************************************************************/
  assign rd_n2   = |opc[11:9] || !opc[8] || opc[7];
  assign rd_nz   = |opc[11:7];
  assign imm6_nz = opc[12] || |opc[6:2];
  assign imm8_nz = |opc[12:5];
  assign rs2_nz  = |opc[6:2];

  assign c_rd    = opc[11:7];
  assign c_rdp   = {2'b01, opc[4:2]};
  assign c_rs1   = opc[11:7];
  assign c_rs1p  = {2'b01, opc[9:7]};
  assign c_rs2   = opc[6:2];
  assign c_rs2p  = {2'b01, opc[4:2]};

  /*****************************************************************************************/
  /* compressed quadrant 0 expansion                                                       */
  /*****************************************************************************************/
  always @ (opc or imm8_nz or c_rdp or c_rs1p or c_rs2p) begin
    case (opc[15:13])
      3'b000:  e_c0 = (imm8_nz) ? {2'h0, opc[10:7], opc[12:11], opc[5], opc[6], 2'h0, `X2,
                                   3'h0, c_rdp, `OP_IMM} : `RV32C_BAD;
      3'b010:  e_c0 = {5'h0, opc[5], opc[12:10], opc[6], 2'h0, c_rs1p, 3'h2, c_rdp, `OP_LD};
      3'b110:  e_c0 = {5'h0, opc[5], opc[12], c_rs2p, c_rs1p, 3'h2, opc[11:10], opc[6], 2'h0,
                       `OP_ST};
      default: e_c0 = `RV32C_BAD;
      endcase
    end

  /*****************************************************************************************/
  /* compressed quadrant 1 expansion                                                       */
  /*****************************************************************************************/
  always @ (opc or imm6_nz or rd_n2 or rd_nz or c_rd or c_rs1p or c_rs2p) begin
    casex ({opc[15:13], opc[11:10]})
      5'b000xx: e_c1 = (!rd_nz)  ? {25'h0000000, `OP_IMM} :
                       (imm6_nz) ? { {7{opc[12]}}, opc[6:2], c_rd, 3'h0, c_rd, `OP_IMM} :
                                    `RV32C_BAD;
      5'b001xx: e_c1 = {opc[12], opc[8], opc[10:9], opc[6], opc[7], opc[2], opc[11],
                        opc[5:3], {9{opc[12]}}, `X1, `OP_JAL};
      5'b010xx: e_c1 = { {7{opc[12]}}, opc[6:2], `X0, 3'h0, c_rd, `OP_IMM};
      5'b011xx: e_c1 = (rd_n2) ? { {15{opc[12]}}, opc[6:2], c_rd, `OP_LUI} :
                                 { {3{opc[12]}}, opc[4:3], opc[5], opc[2], opc[6], 4'h0,
                                  c_rd, 3'h0, c_rd, `OP_IMM};
      5'b10000: e_c1 = {7'h00, opc[6:2], c_rs1p, 3'h5, c_rs1p, `OP_IMM};
      5'b10001: e_c1 = {7'h20, opc[6:2], c_rs1p, 3'h5, c_rs1p, `OP_IMM};
      5'b10010: e_c1 = { {7{opc[12]}}, opc[6:2], c_rs1p, 3'h7, c_rs1p, `OP_IMM};
      5'b10011: e_c1 = (opc[12]) ? `RV32C_BAD :
                                   {1'h0, ~|opc[6:5], 5'h0, c_rs2p, c_rs1p, |opc[6:5],
                                    opc[6], &opc[6:5], c_rs1p, `OP_IMM};
      5'b101xx: e_c1 = {opc[12], opc[8], opc[10:9], opc[6], opc[7], opc[2], opc[11],
                        opc[5:3], {9{opc[12]}}, `X0, `OP_JAL};
      5'b110xx: e_c1 = { {4{opc[12]}}, opc[6:5], opc[2], 5'h0, c_rs1p, 3'b0, opc[11:10],
                        opc[4:3], opc[12], `OP_BR};
      5'b111xx: e_c1 = { {4{opc[12]}}, opc[6:5], opc[2], 5'h0, c_rs1p, 3'b1, opc[11:10],
                        opc[4:3], opc[12], `OP_BR};
      endcase
    end

  /*****************************************************************************************/
  /* compressed quadrant 2 expansion                                                       */
  /*****************************************************************************************/
  always @ (opc or rd_nz or rs2_nz or c_rd or c_rs1 or c_rs2) begin
    casex (opc[15:12])
      4'b000x: e_c2 = {7'h0, opc[6:2], c_rd, 3'h1, c_rd, `OP_IMM};
      4'b010x: e_c2 = (rd_nz) ? {4'h0, opc[3:2], opc[12], opc[6:4], 2'h0, `X2, 3'h2, c_rd,
                                 `OP_LD} : `RV32C_BAD;
      4'b1000: e_c2 = (rs2_nz) ? {7'h0, c_rs2, `X0, 3'h0, c_rd, `OP_OP} :
                      (rd_nz)  ? {12'h0, c_rs1, 3'h0, `X0, `OP_JALR} : `RV32C_BAD;
      4'b1001: e_c2 = (rs2_nz) ? {7'h0, c_rs2, c_rd, 3'h0, c_rd, `OP_OP} :
                      (rd_nz)  ? {12'h0, c_rs1, 3'h0, `X1, `OP_JALR} :
                                 {25'h0002000, `OP_SYS};
      4'b110x: e_c2 = {4'h0, opc[8:7], opc[12], c_rs2, `X2, 3'h2, opc[11:9], 2'h0, `OP_ST};
      default: e_c2 = `RV32C_BAD;
      endcase
    end

  /*****************************************************************************************/
  /* opcode select                                                                         */
  /*****************************************************************************************/
  assign inst = (&opc[1:0])         ? opc[31:2] :
                (opc[1] && !opc[0]) ? e_c2      :
                (opc[0])            ? e_c1      : e_c0;

  /*****************************************************************************************/
  /* opcode fields                                                                         */
  /*****************************************************************************************/
  assign rd_3_addr  = inst[11:7];
  assign opc_3_out  = {inst[14:12], inst[6:2]};
  assign rs1_3_addr = inst[19:15];
  assign rs2_3_addr = inst[24:20];

  always @ (inst) begin
    case (inst[6:2])
      `OP_AUI,
      `OP_LUI: imm_3_out = {inst[31:12], 12'h0 };
      `OP_ST:  imm_3_out = {{21{inst[31]}}, inst[30:25], inst[11:8], inst[7]};
      `OP_BR:  imm_3_out = {{20{inst[31]}}, inst[7],  inst[30:25], inst[11:8],  1'b0};
      `OP_JAL: imm_3_out = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
      default: imm_3_out = {{21{inst[31]}}, inst[30:20]};
      endcase
    end

  /*****************************************************************************************/
  /* clock 4 - register read and late decode                                               */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      dst_6d_data <= 32'h0;
      imm_4_reg   <= 32'h0;
      opc_4_reg   <=  8'h0;
      pc_4_reg    <= `RST_BASE;
      rd_4_reg    <=  5'h0;
      rs1_4_reg   <=  5'h0;
      rs1by_4_reg <=  1'b0;
      rs1z_4_reg  <=  1'b0;
      rs2_4_reg   <=  5'h0;
      rs2by_4_reg <=  1'b0;
      rs2z_4_reg  <=  1'b0;
      valid_4_reg <=  1'b0;
      end
    else if (run_exe) begin
      if (wr_6_en) dst_6d_data <= dst_6_data;
      imm_4_reg   <= imm_3_out;
      opc_4_reg   <= opc_3_out;
      pc_4_reg    <= pc_3_reg;
      rd_4_reg    <= rd_3_addr;
      rs1_4_reg   <= rs1_3_addr;
      rs1by_4_reg <= wr_6_en && ~|(rs1_3_addr ^ rd_6_reg);
      rs1z_4_reg  <= ~|rs1_3_addr;
      rs2_4_reg   <= rs2_3_addr;
      rs2by_4_reg <= wr_6_en && ~|(rs2_3_addr ^ rd_6_reg);
      rs2z_4_reg  <= ~|rs2_3_addr;
      valid_4_reg <= !ld_pc && valid_3_reg;
      end
    end

  /*****************************************************************************************/
  /* register file, with write bypass                                                      */
  /*****************************************************************************************/
`ifdef INSTANCE_REG
  inst_reg REG    ( .src1_data(src1_4_rdata), .src2_data(src2_4_rdata), .clk(clk),
                    .dst_addr(rd_6_reg), .dst_data(dst_6_data), .reg_enabl(run_exe),
                    .src1_addr(rs1_3_addr), .src2_addr(rs2_3_addr), .wr_enabl(wr_6_en) );
`else
  always @ (posedge clk) begin
    if (run_exe) begin
      src1_4_rdata <= regf_mem[rs1_3_addr];
      src2_4_rdata <= regf_mem[rs2_3_addr];
      if (wr_6_en) regf_mem[rd_6_reg] <= dst_6_data;
      end
    end
`endif

  assign src1_4_out = (rs1z_4_reg)  ? 32'h0       :
                      (src1_4_byp)  ? dst_6_data  :
                      (rs1by_4_reg) ? dst_6d_data : src1_4_rdata;
  assign src2_4_out = (rs2z_4_reg)  ? 32'h0       :
                      (src2_4_byp)  ? dst_6_data  :
                      (rs2by_4_reg) ? dst_6d_data : src2_4_rdata;

  /*****************************************************************************************/
  /* major opcode                                                                          */
  /*****************************************************************************************/
  assign opc_4_aui  = (opc_4_reg[4:0] == `OP_AUI);
  assign opc_4_br   = (opc_4_reg[4:0] == `OP_BR);
  assign opc_4_fnc  = (opc_4_reg[4:0] == `OP_FNC);
  assign opc_4_imm  = (opc_4_reg[4:0] == `OP_IMM);
  assign opc_4_jal  = (opc_4_reg[4:0] == `OP_JAL);
  assign opc_4_jalr = (opc_4_reg[4:0] == `OP_JALR);
  assign opc_4_ld   = (opc_4_reg[4:0] == `OP_LD);
  assign opc_4_lui  = (opc_4_reg[4:0] == `OP_LUI);
  assign opc_4_op   = (opc_4_reg[4:0] == `OP_OP);
  assign opc_4_st   = (opc_4_reg[4:0] == `OP_ST);
  assign opc_4_sys  = (opc_4_reg[4:0] == `OP_SYS);
  assign opc_4_amo  = (opc_4_reg[4:0] == `OP_AMO);

  /*****************************************************************************************/
  /* funct3                                                                                */
  /*****************************************************************************************/
  assign fn3_4_0    = (opc_4_reg[7:5] == 3'b000);
  assign fn3_4_1    = (opc_4_reg[7:5] == 3'b001);
  assign fn3_4_2    = (opc_4_reg[7:5] == 3'b010);
  assign fn3_4_3    = (opc_4_reg[7:5] == 3'b011);
  assign fn3_4_4    = (opc_4_reg[7:5] == 3'b100);
  assign fn3_4_5    = (opc_4_reg[7:5] == 3'b101);
  assign fn3_4_6    = (opc_4_reg[7:5] == 3'b110);
  assign fn3_4_7    = (opc_4_reg[7:5] == 3'b111);

  /*****************************************************************************************/
  /* funct7                                                                                */
  /*****************************************************************************************/
  assign fn7_4_00   = ~|imm_4_reg[11:5];
  assign fn7_4_04   =  (imm_4_reg[11:5] == 7'h04);
  assign fn7_4_10   =  (imm_4_reg[11:5] == 7'h10);
  assign fn7_4_14   =  (imm_4_reg[11:5] == 7'h14);
  assign fn7_4_20   =  (imm_4_reg[11:5] == 7'h20);
  assign fn7_4_24   =  (imm_4_reg[11:5] == 7'h24);
  assign fn7_4_30   =  (imm_4_reg[11:5] == 7'h30);
  assign fn7_4_34   =  (imm_4_reg[11:5] == 7'h34);

  assign fn7_4_00x  =  (imm_4_reg[11:7] == 5'b00000);
  assign fn7_4_04x  =  (imm_4_reg[11:7] == 5'b00001);
  assign fn7_4_10x  =  (imm_4_reg[11:7] == 5'b00100);
  assign fn7_4_20x  =  (imm_4_reg[11:7] == 5'b01000);
  assign fn7_4_30x  =  (imm_4_reg[11:7] == 5'b01100);

  /*****************************************************************************************/
  /* opcode special cases                                                                  */
  /*****************************************************************************************/
  assign fn5_4_04   =  (imm_4_reg[4:0] == 5'h04);
  assign fn5_4_05   =  (imm_4_reg[4:0] == 5'h05);
  assign fn5_4_07   =  (imm_4_reg[4:0] == 5'h07);
  assign fn5_4_0f   =  (imm_4_reg[4:0] == 5'h0f);
  assign fn5_4_18   =  (imm_4_reg[4:0] == 5'h18);
  assign fn5_4_1f   =  (imm_4_reg[4:0] == 5'h1f);

  assign rr_4_zer   = ~|rd_4_reg && ~|rs1_4_reg;

  /*****************************************************************************************/
  /* alu decodes                                                                           */
  /*****************************************************************************************/
  assign aop_4_add   = (opc_4_op   && fn3_4_0 && fn7_4_00) ||                 /* add       */
                       (opc_4_op   && fn3_4_0 && fn7_4_20) ||                 /* sub       */
                       (opc_4_imm  && fn3_4_0) ||                             /* addi      */
                       (opc_4_ld   && fn3_4_0) ||                             /* lb        */
                       (opc_4_ld   && fn3_4_1) ||                             /* lh        */
                       (opc_4_ld   && fn3_4_2) ||                             /* lw        */
                       (opc_4_ld   && fn3_4_4) ||                             /* lbu       */
                       (opc_4_ld   && fn3_4_5) ||                             /* lhu       */
                       (opc_4_jalr && fn3_4_0) ||                             /* jalr      */
                        opc_4_aui ||                                          /* auipc     */
                        opc_4_jal;                                            /* jal       */
  assign aop_4_or    = (opc_4_op   && fn3_4_6 && fn7_4_00) ||                 /* or        */
                       (opc_4_imm  && fn3_4_6) ||                             /* ori       */
                       (opc_4_op   && fn3_4_6 && fn7_4_20) ||                 /* orn       */
                       (opc_4_op   && fn3_4_1 && fn7_4_14) ||                 /* sbset     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_14);                   /* sbseti    */
  assign aop_4_and   = (opc_4_op   && fn3_4_7 && fn7_4_00) ||                 /* and       */
                       (opc_4_imm  && fn3_4_7) ||                             /* andi      */
                       (opc_4_op   && fn3_4_7 && fn7_4_20) ||                 /* andn      */
                       (opc_4_op   && fn3_4_1 && fn7_4_24) ||                 /* sbclr     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_24);                   /* sbclri    */
  assign aop_4_xor   = (opc_4_op   && fn3_4_4 && fn7_4_00) ||                 /* xor       */
                       (opc_4_imm  && fn3_4_4) ||                             /* xori      */
                       (opc_4_op   && fn3_4_4 && fn7_4_20) ||                 /* xnor      */
                       (opc_4_op   && fn3_4_1 && fn7_4_34) ||                 /* sbinv     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_34);                   /* sbinvi    */

  /*****************************************************************************************/
  /* alu external decodes                                                                  */
  /*****************************************************************************************/
  assign aop_4_sl    = (opc_4_op   && fn3_4_1 && fn7_4_00) ||                 /* sll       */
                       (opc_4_imm  && fn3_4_1 && fn7_4_00) ||                 /* slli      */
                       (opc_4_op   && fn3_4_1 && fn7_4_10) ||                 /* slo       */
                       (opc_4_imm  && fn3_4_1 && fn7_4_10);                   /* sloi      */
  assign aop_4_sr    = (opc_4_op   && fn3_4_5 && fn7_4_00) ||                 /* srl       */
                       (opc_4_imm  && fn3_4_5 && fn7_4_00) ||                 /* srli      */
                       (opc_4_op   && fn3_4_5 && fn7_4_20) ||                 /* sra       */
                       (opc_4_imm  && fn3_4_5 && fn7_4_20) ||                 /* srai      */
                       (opc_4_op   && fn3_4_5 && fn7_4_10) ||                 /* sro       */
                       (opc_4_imm  && fn3_4_5 && fn7_4_10);                   /* sroi      */
  assign aop_4_rol   = (opc_4_op   && fn3_4_1 && fn7_4_30);                   /* rol       */
  assign aop_4_ror   = (opc_4_op   && fn3_4_5 && fn7_4_30) ||                 /* ror       */
                       (opc_4_imm  && fn3_4_5 && fn7_4_30);                   /* rori      */
  assign aop_4_shfl  = (opc_4_imm  && fn3_4_5 && fn7_4_34 && fn5_4_07) ||     /* rev.b     */
                       (opc_4_imm  && fn3_4_5 && fn7_4_34 && fn5_4_0f) ||     /* rev.h     */
                       (opc_4_imm  && fn3_4_5 && fn7_4_34 && fn5_4_18) ||     /* rev8      */
                       (opc_4_imm  && fn3_4_5 && fn7_4_34 && fn5_4_1f) ||     /* rev       */
                       (opc_4_imm  && fn3_4_1 && fn7_4_30 && fn5_4_04) ||     /* sext.b    */
                       (opc_4_imm  && fn3_4_1 && fn7_4_30 && fn5_4_05);       /* sext.h    */
  assign aop_4_pack  = (opc_4_op   && fn3_4_4 && fn7_4_04) ||                 /* pack      */
                       (opc_4_op   && fn3_4_4 && fn7_4_24) ||                 /* packu     */
                       (opc_4_op   && fn3_4_7 && fn7_4_04);                   /* packh     */

  /*****************************************************************************************/
  /* alu test decodes                                                                      */
  /*****************************************************************************************/
  assign sbext_4_dec = (opc_4_op   && fn3_4_5 && fn7_4_24) ||                 /* sbext     */
                       (opc_4_imm  && fn3_4_5 && fn7_4_24);                   /* sbexti    */
  assign slt_4_dec   = (opc_4_op   && fn3_4_2 && fn7_4_00) ||                 /* slt       */
                       (opc_4_imm  && fn3_4_2);                               /* slti      */
  assign sltu_4_dec  = (opc_4_op   && fn3_4_3 && fn7_4_00) ||                 /* sltu      */
                       (opc_4_imm  && fn3_4_3);                               /* sltiu     */

  /*****************************************************************************************/
  /* bit select decodes                                                                    */
  /*****************************************************************************************/
  assign bits_4_dec  = (opc_4_op   && fn3_4_1 && fn7_4_14) ||                 /* sbset     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_14) ||                 /* sbseti    */
                       (opc_4_op   && fn3_4_1 && fn7_4_24) ||                 /* sbclr     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_24) ||                 /* sbclri    */
                       (opc_4_op   && fn3_4_1 && fn7_4_34) ||                 /* sbinv     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_34);                   /* sbinvi    */

  /*****************************************************************************************/
  /* invert b input decodes                                                                */
  /*****************************************************************************************/
  assign invb_4_dec  = (opc_4_op   && fn3_4_0 && fn7_4_20) ||                 /* sub       */
                       (opc_4_op   && fn3_4_4 && fn7_4_20) ||                 /* xnor      */
                       (opc_4_op   && fn3_4_6 && fn7_4_20) ||                 /* orn       */
                       (opc_4_op   && fn3_4_7 && fn7_4_20) ||                 /* andn      */
                       (opc_4_op   && fn3_4_1 && fn7_4_24) ||                 /* sbclr     */
                       (opc_4_imm  && fn3_4_1 && fn7_4_24);                   /* sbclri    */

  /*****************************************************************************************/
  /* non-alu decodes                                                                       */
  /*****************************************************************************************/
  assign amo_4_dec   = (opc_4_amo  && fn3_4_2 && fn7_4_00x) ||                /* amoadd.w  */
                       (opc_4_amo  && fn3_4_2 && fn7_4_04x) ||                /* amoswap.w */
                       (opc_4_amo  && fn3_4_2 && fn7_4_10x) ||                /* amoxor.w  */
                       (opc_4_amo  && fn3_4_2 && fn7_4_20x) ||                /* amoor.w   */
                       (opc_4_amo  && fn3_4_2 && fn7_4_30x);                  /* amoand.w  */
  assign br_4_dec    = (opc_4_br   && fn3_4_0) ||                             /* beq       */
                       (opc_4_br   && fn3_4_1) ||                             /* bne       */
                       (opc_4_br   && fn3_4_4) ||                             /* blt       */
                       (opc_4_br   && fn3_4_5) ||                             /* bge       */
                       (opc_4_br   && fn3_4_6) ||                             /* bltu      */
                       (opc_4_br   && fn3_4_7);                               /* bgeu      */
  assign fnc_4_dec   = (opc_4_fnc  && fn3_4_0) ||                             /* fence     */
                       (opc_4_fnc  && fn3_4_1);                               /* fence.i   */
  assign ld_4_dec    = (opc_4_ld   && fn3_4_0) ||                             /* lb        */
                       (opc_4_ld   && fn3_4_1) ||                             /* lh        */
                       (opc_4_ld   && fn3_4_2) ||                             /* lw        */
                       (opc_4_ld   && fn3_4_4) ||                             /* lbu       */
                       (opc_4_ld   && fn3_4_5);                               /* lhu       */
  assign st_4_dec    = (opc_4_st   && fn3_4_0) ||                             /* sb        */
                       (opc_4_st   && fn3_4_1) ||                             /* sh        */
                       (opc_4_st   && fn3_4_2);                               /* sw        */

  /*****************************************************************************************/
  /* shift amount source decodes                                                           */
  /*****************************************************************************************/
  assign shftd_4_dec = (opc_4_op   && fn3_4_1) ||                             /* register  */
                       (opc_4_op   && fn3_4_5);
  assign shfti_4_dec = (opc_4_imm  && fn3_4_1) ||                             /* immediate */
                       (opc_4_imm  && fn3_4_5);

  /*****************************************************************************************/
  /* unique instruction decodes                                                            */
  /*****************************************************************************************/
  assign csr_4_dec   = (opc_4_sys && fn3_4_1) ||                              /* csrrw     */
                       (opc_4_sys && fn3_4_2) ||                              /* csrrs     */
                       (opc_4_sys && fn3_4_3) ||                              /* csrrc     */
                       (opc_4_sys && fn3_4_5) ||                              /* csrrwi    */
                       (opc_4_sys && fn3_4_6) ||                              /* csrrsi    */
                       (opc_4_sys && fn3_4_7);                                /* csrrci    */
  assign dret_4_dec  =  opc_4_sys && fn3_4_0 &&  (imm_4_reg[11:0] == 12'h7b2) && rr_4_zer;
  assign ebrk_4_dec  =  opc_4_sys && fn3_4_0 &&  (imm_4_reg[11:0] == 12'h001) && rr_4_zer;
  assign ecall_4_dec =  opc_4_sys && fn3_4_0 && ~|imm_4_reg[11:0]             && rr_4_zer;
  assign eret_4_dec  =  opc_4_sys && fn3_4_0 &&  (imm_4_reg[11:0] == 12'h302) && rr_4_zer;
  assign wfi_4_dec   =  opc_4_sys && fn3_4_0 &&  (imm_4_reg[11:0] == 12'h105) && rr_4_zer;

  /*****************************************************************************************/
  /* register write decode                                                                 */
  /*****************************************************************************************/
  assign wreg_4_out  = aop_4_add   || aop_4_or  || aop_4_and  || aop_4_xor  || aop_4_sl   ||
                       aop_4_sr    || aop_4_rol || aop_4_ror  || aop_4_shfl || aop_4_pack ||
                       sbext_4_dec || slt_4_dec || sltu_4_dec || opc_4_lui  || amo_4_dec  ||
                       (csr_4_dec && csr_4_ok);

  /*****************************************************************************************/
  /* csr check                                                                             */
  /*****************************************************************************************/
  assign csr_achk    = (csr_4_dec) ? imm_4_reg[11:0] : 12'h0;
  assign csr_4_ok    = ((&imm_4_reg[11:10] && opc_4_reg[6] && ~|rs1_4_reg) ||
                        ~&imm_4_reg[11:10]) && (csr_ok_ext || csr_ok_int);

  /*****************************************************************************************/
  /* special debug                                                                         */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      dbg_int <= 1'b0;
      ss_reg  <= 1'b0;
      end
    else begin
      dbg_int <= dbg_req;
      ss_reg  <= step_reg && !debug_mode && (inst_5_ret || ss_reg);
      end
    end

  assign dbg_4_out   = brk_req || dbg_int || (ebrk_4_dec && ebrkd_reg) || halt_reg || ss_reg;

  /*****************************************************************************************/
  /* clock 5 - execute                                                                     */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      a_add_5_reg <=  1'b0;                                /* alu: add                     */
      a_ain_5_reg <=  1'b0;                                /* alu: pass ain                */
      a_and_5_reg <=  1'b0;                                /* alu: and                     */
      a_bin_5_reg <=  1'b0;                                /* alu: pass bin                */
      a_ext_5_reg <=  1'b0;                                /* alu: external                */
      a_or_5_reg  <=  1'b0;                                /* alu: or                      */
      a_tst_5_reg <=  1'b0;                                /* alu: test                    */
      a_xor_5_reg <=  1'b0;                                /* alu: xor                     */
      alta_5_reg  <=  1'b0;                                /* alt ain (pc)                 */
      altb_5_reg  <=  1'b0;                                /* alt bin (imm)                */
      amo_5_reg   <=  1'b0;                                /* amo inst                     */
      bits_5_reg  <=  1'b0;                                /* alt bin (bit sel)            */
      br_5_reg    <=  6'h0;                                /* br inst                      */
      csrop_5_reg <=  5'h0;                                /* csr inst                     */
      dbg_5_reg   <=  3'h0;
      dret_5_reg  <=  1'b0;                                /* dret inst                    */
      ebrk_5_reg  <=  1'b0;                                /* ebrk inst                    */
      ecall_5_reg <=  1'b0;                                /* ecall inst                   */
      eret_5_reg  <=  1'b0;                                /* eret inst                    */
      flush_5_reg <=  1'b0;                                /* flush pipeline               */
      imm_5_reg   <= 32'h0;                                /* imm data                     */
      invb_5_reg  <=  1'b0;                                /* invert bin                   */
      irq_5_reg   <=  6'h0;
      jal_5_reg   <=  1'b0;                                /* jal/jalr inst                */
      ld_5_reg    <=  1'b0;                                /* ld inst                      */
      mli_5_reg   <= `EC_NULL;
      nmi_5_reg   <=  1'b0;                                /* nmi pending                  */
      opc_5_reg   <=  3'h0;
      pack_5_reg  <=  1'b0;                                /* pack inst                    */
      pc_5_reg    <= `RST_BASE;                            /* pc                           */
      rd_5_reg    <=  5'h0;                                /* rd select                    */
      rol_5_reg   <=  1'b0;                                /* rol inst                     */
      ror_5_reg   <=  1'b0;                                /* ror inst                     */
      rs1_5_reg   <=  5'h0;                                /* rs1 select                   */
      sbext_5_reg <=  1'b0;                                /* sbext inst                   */
      shfl_5_reg  <=  1'b0;                                /* rev/sext inst                */
      shftd_5_reg <=  1'b0;                                /* shamt reg                    */
      shfti_5_reg <=  1'b0;                                /* shamt imm                    */
      src1_5_reg  <= 32'h0;                                /* src1 data                    */
      src2_5_reg  <= 32'h0;                                /* src2 data                    */
      sl_5_reg    <=  1'b0;                                /* sl/slo inst                  */
      slt_5_reg   <=  1'b0;                                /* slt inst                     */
      sltu_5_reg  <=  1'b0;                                /* sltu inst                    */
      sr_5_reg    <=  1'b0;                                /* sra/srl/sro inst             */
      st_5_reg    <=  1'b0;                                /* st inst                      */
      trap_5_reg  <=  1'b0;                                /* trap detect                  */
      wfi_5_reg   <=  1'b0;                                /* wfi inst                     */
      valid_5_reg <=  1'b0;
      wreg_5_reg  <=  1'b0;                                /* reg write                    */
      end
    else if (run_exe) begin
      a_add_5_reg <=  aop_4_add || br_4_dec || st_4_dec;
      a_ain_5_reg <=  amo_4_dec;
      a_and_5_reg <=  aop_4_and;
      a_bin_5_reg <=  opc_4_lui || csr_4_dec;
      a_ext_5_reg <=  aop_4_rol || aop_4_ror || aop_4_sl || aop_4_sr ||
                      aop_4_shfl || aop_4_pack;
      a_or_5_reg  <=  aop_4_or;
      a_tst_5_reg <=  sbext_4_dec || slt_4_dec || sltu_4_dec;
      a_xor_5_reg <=  aop_4_xor;
      alta_5_reg  <=  opc_4_aui || opc_4_br || opc_4_jal;
      altb_5_reg  <= !opc_4_op;
      amo_5_reg   <=  amo_4_dec;
      bits_5_reg  <= bits_4_dec;
      br_5_reg    <= (opc_4_br) ? {fn3_4_7, fn3_4_6, fn3_4_5,
                                   fn3_4_4, fn3_4_1, fn3_4_0} : 6'h0;
      csrop_5_reg <= (csr_4_dec && csr_4_ok) ? {csr_ok_int, opc_4_reg[7],
                                                (fn3_4_1 || fn3_4_5),
                                                (fn3_4_3 || fn3_4_7), (fn3_4_2 || fn3_4_6)} :
                                                5'h0;
      dbg_5_reg   <= (brk_req)                 ? `DC_BRK :
                     (ebrk_4_dec && ebrkd_reg) ? `DC_SW  :
                     (halt_reg)                ? `DC_HLT :
                     (dbg_int)                 ? `DC_DBG : `DC_STEP;
      dret_5_reg  <= dret_4_dec && debug_mode;
      ebrk_5_reg  <= ebrk_4_dec;
      ecall_5_reg <= ecall_4_dec;
      eret_5_reg  <= eret_4_dec;
      flush_5_reg <= fnc_4_dec || (wfi_4_dec && !debug_mode);
      imm_5_reg   <= imm_4_reg;
      invb_5_reg  <= invb_4_dec;
      irq_5_reg   <= (debug_mode) ? 6'h0 : {dbg_4_out, irq_bus};
      jal_5_reg   <= opc_4_jal || (opc_4_jalr && fn3_4_0);
      ld_5_reg    <= ld_4_dec;
      mli_5_reg   <= mli_code;
      nmi_5_reg   <= irq_bus[4];
      opc_5_reg   <= opc_4_reg[7:5];
      pack_5_reg  <= aop_4_pack;
      pc_5_reg    <= pc_4_reg;
      rd_5_reg    <= rd_4_reg;
      rol_5_reg   <= aop_4_rol;
      ror_5_reg   <= aop_4_ror;
      rs1_5_reg   <= rs1_4_reg;
      sbext_5_reg <= sbext_4_dec;
      shfl_5_reg  <= aop_4_shfl;
      shftd_5_reg <= shftd_4_dec;
      shfti_5_reg <= shfti_4_dec;
      src1_5_reg  <= src1_4_out;
      src2_5_reg  <= src2_4_out;
      sl_5_reg    <= aop_4_sl;
      slt_5_reg   <= slt_4_dec;
      sltu_5_reg  <= sltu_4_dec;
      sr_5_reg    <= aop_4_sr;
      st_5_reg    <= st_4_dec;
      trap_5_reg  <= valid_4_reg && !(wreg_4_out || br_4_dec || fnc_4_dec || ecall_4_dec ||
                                      eret_4_dec || st_4_dec  || wfi_4_dec || ebrk_4_dec ||
                                      (dret_4_dec && debug_mode)); 
      valid_5_reg <= !ld_pc && valid_4_reg;
      wfi_5_reg   <= (wfi_4_dec && !debug_mode);
      wreg_5_reg  <= wreg_4_out;
      end
    end

  /*****************************************************************************************/
  /* register bypass                                                                       */
  /*****************************************************************************************/
  assign src1_5_out  = (src1_5_byp) ? dst_6_data : src1_5_reg;
  assign src2_5_out  = (src2_5_byp) ? dst_6_data : src2_5_reg;

  /*****************************************************************************************/
  /* shift/rotate common                                                                   */
  /*****************************************************************************************/
  assign shft_5_inp  = imm_5_reg[9] || (imm_5_reg[10] && src1_5_out[31]);
  assign shamt_5_out = (shftd_5_reg) ? src2_5_out[4:0] :
                       (shfti_5_reg) ?  imm_5_reg[4:0] : 5'h0;
  assign shamt_5_cmp = ~shamt_5_out + 1'b1;
  assign slamt_5_out = (ror_5_reg) ? shamt_5_cmp : shamt_5_out;
  assign sramt_5_out = (rol_5_reg) ? shamt_5_cmp : shamt_5_out;

  /*****************************************************************************************/
  /* shift left (sll, slo)                                                                 */
  /*****************************************************************************************/
  always @ (slamt_5_out or src1_5_out or shft_5_inp) begin
    case (slamt_5_out)
      5'h01:   sl_5_mux = {src1_5_out[30:0],     shft_5_inp};
      5'h02:   sl_5_mux = {src1_5_out[29:0],  {2{shft_5_inp}}};
      5'h03:   sl_5_mux = {src1_5_out[28:0],  {3{shft_5_inp}}};
      5'h04:   sl_5_mux = {src1_5_out[27:0],  {4{shft_5_inp}}};
      5'h05:   sl_5_mux = {src1_5_out[26:0],  {5{shft_5_inp}}};
      5'h06:   sl_5_mux = {src1_5_out[25:0],  {6{shft_5_inp}}};
      5'h07:   sl_5_mux = {src1_5_out[24:0],  {7{shft_5_inp}}};
      5'h08:   sl_5_mux = {src1_5_out[23:0],  {8{shft_5_inp}}};
      5'h09:   sl_5_mux = {src1_5_out[22:0],  {9{shft_5_inp}}};
      5'h0a:   sl_5_mux = {src1_5_out[21:0], {10{shft_5_inp}}};
      5'h0b:   sl_5_mux = {src1_5_out[20:0], {11{shft_5_inp}}};
      5'h0c:   sl_5_mux = {src1_5_out[19:0], {12{shft_5_inp}}};
      5'h0d:   sl_5_mux = {src1_5_out[18:0], {13{shft_5_inp}}};
      5'h0e:   sl_5_mux = {src1_5_out[17:0], {14{shft_5_inp}}};
      5'h0f:   sl_5_mux = {src1_5_out[16:0], {15{shft_5_inp}}};
      5'h10:   sl_5_mux = {src1_5_out[15:0], {16{shft_5_inp}}};
      5'h11:   sl_5_mux = {src1_5_out[14:0], {17{shft_5_inp}}};
      5'h12:   sl_5_mux = {src1_5_out[13:0], {18{shft_5_inp}}};
      5'h13:   sl_5_mux = {src1_5_out[12:0], {19{shft_5_inp}}};
      5'h14:   sl_5_mux = {src1_5_out[11:0], {20{shft_5_inp}}};
      5'h15:   sl_5_mux = {src1_5_out[10:0], {21{shft_5_inp}}};
      5'h16:   sl_5_mux = {src1_5_out[9:0],  {22{shft_5_inp}}};
      5'h17:   sl_5_mux = {src1_5_out[8:0],  {23{shft_5_inp}}};
      5'h18:   sl_5_mux = {src1_5_out[7:0],  {24{shft_5_inp}}};
      5'h19:   sl_5_mux = {src1_5_out[6:0],  {25{shft_5_inp}}};
      5'h1a:   sl_5_mux = {src1_5_out[5:0],  {26{shft_5_inp}}};
      5'h1b:   sl_5_mux = {src1_5_out[4:0],  {27{shft_5_inp}}};
      5'h1c:   sl_5_mux = {src1_5_out[3:0],  {28{shft_5_inp}}};
      5'h1d:   sl_5_mux = {src1_5_out[2:0],  {29{shft_5_inp}}};
      5'h1e:   sl_5_mux = {src1_5_out[1:0],  {30{shft_5_inp}}};
      5'h1f:   sl_5_mux = {src1_5_out[0],    {31{shft_5_inp}}};
      default: sl_5_mux =  src1_5_out;
      endcase
    end

  assign sl_5_out = (sl_5_reg) ? sl_5_mux : 32'h0;

  /*****************************************************************************************/
  /* shift right (sra, srl, sro)                                                           */
  /*****************************************************************************************/
  always @ (sramt_5_out or src1_5_out or shft_5_inp) begin
    case (sramt_5_out)
      5'h01:   sr_5_mux = {    shft_5_inp,   src1_5_out[31:1] };
      5'h02:   sr_5_mux = { {2{shft_5_inp}}, src1_5_out[31:2] };
      5'h03:   sr_5_mux = { {3{shft_5_inp}}, src1_5_out[31:3] };
      5'h04:   sr_5_mux = { {4{shft_5_inp}}, src1_5_out[31:4] };
      5'h05:   sr_5_mux = { {5{shft_5_inp}}, src1_5_out[31:5] };
      5'h06:   sr_5_mux = { {6{shft_5_inp}}, src1_5_out[31:6] };
      5'h07:   sr_5_mux = { {7{shft_5_inp}}, src1_5_out[31:7] };
      5'h08:   sr_5_mux = { {8{shft_5_inp}}, src1_5_out[31:8] };
      5'h09:   sr_5_mux = { {9{shft_5_inp}}, src1_5_out[31:9] };
      5'h0a:   sr_5_mux = {{10{shft_5_inp}}, src1_5_out[31:10]};
      5'h0b:   sr_5_mux = {{11{shft_5_inp}}, src1_5_out[31:11]};
      5'h0c:   sr_5_mux = {{12{shft_5_inp}}, src1_5_out[31:12]};
      5'h0d:   sr_5_mux = {{13{shft_5_inp}}, src1_5_out[31:13]};
      5'h0e:   sr_5_mux = {{14{shft_5_inp}}, src1_5_out[31:14]};
      5'h0f:   sr_5_mux = {{15{shft_5_inp}}, src1_5_out[31:15]};
      5'h10:   sr_5_mux = {{16{shft_5_inp}}, src1_5_out[31:16]};
      5'h11:   sr_5_mux = {{17{shft_5_inp}}, src1_5_out[31:17]};
      5'h12:   sr_5_mux = {{18{shft_5_inp}}, src1_5_out[31:18]};
      5'h13:   sr_5_mux = {{19{shft_5_inp}}, src1_5_out[31:19]};
      5'h14:   sr_5_mux = {{20{shft_5_inp}}, src1_5_out[31:20]};
      5'h15:   sr_5_mux = {{21{shft_5_inp}}, src1_5_out[31:21]};
      5'h16:   sr_5_mux = {{22{shft_5_inp}}, src1_5_out[31:22]};
      5'h17:   sr_5_mux = {{23{shft_5_inp}}, src1_5_out[31:23]};
      5'h18:   sr_5_mux = {{24{shft_5_inp}}, src1_5_out[31:24]};
      5'h19:   sr_5_mux = {{25{shft_5_inp}}, src1_5_out[31:25]};
      5'h1a:   sr_5_mux = {{26{shft_5_inp}}, src1_5_out[31:26]};
      5'h1b:   sr_5_mux = {{27{shft_5_inp}}, src1_5_out[31:27]};
      5'h1c:   sr_5_mux = {{28{shft_5_inp}}, src1_5_out[31:28]};
      5'h1d:   sr_5_mux = {{29{shft_5_inp}}, src1_5_out[31:29]};
      5'h1e:   sr_5_mux = {{30{shft_5_inp}}, src1_5_out[31:30]};
      5'h1f:   sr_5_mux = {{31{shft_5_inp}}, src1_5_out[31]   };
      default: sr_5_mux =                    src1_5_out;
      endcase
    end

  assign sr_5_out = (sr_5_reg) ? sr_5_mux : 32'h0;

  /*****************************************************************************************/
  /* rotate (rol, ror)                                                                     */
  /*****************************************************************************************/
  assign rot_5_out = (rol_5_reg || ror_5_reg) ? (sl_5_mux & sr_5_mux) : 32'h0;

  /*****************************************************************************************/
  /* shuffle (rev, sext)                                                                   */
  /*****************************************************************************************/
  assign src1_5_rv0 = {src1_5_out[0],  src1_5_out[1],  src1_5_out[2],  src1_5_out[3],
                       src1_5_out[4],  src1_5_out[5],  src1_5_out[6],  src1_5_out[7] };
  assign src1_5_rv1 = {src1_5_out[8],  src1_5_out[9],  src1_5_out[10], src1_5_out[11],
                       src1_5_out[12], src1_5_out[13], src1_5_out[14], src1_5_out[15]};
  assign src1_5_rv2 = {src1_5_out[16], src1_5_out[17], src1_5_out[18], src1_5_out[19],
                       src1_5_out[20], src1_5_out[21], src1_5_out[22], src1_5_out[23]};
  assign src1_5_rv3 = {src1_5_out[24], src1_5_out[25], src1_5_out[26], src1_5_out[27],
                       src1_5_out[28], src1_5_out[29], src1_5_out[30], src1_5_out[31]};                 

  always @ (shamt_5_out or src1_5_out or src1_5_rv0 or src1_5_rv1 or src1_5_rv2 or
            src1_5_rv3) begin
    case (shamt_5_out)
      5'h04:   shfl_5_mux = { {24{src1_5_out[7]}},  src1_5_out[7:0] };        /* sext.b    */
      5'h05:   shfl_5_mux = { {16{src1_5_out[15]}}, src1_5_out[15:0]};        /* sext.h    */
      5'h18:   shfl_5_mux = {src1_5_out[7:0],   src1_5_out[15:8],
                             src1_5_out[23:16], src1_5_out[31:24]};           /* rev8      */
      5'h07:   shfl_5_mux = {src1_5_rv3, src1_5_rv2, src1_5_rv1, src1_5_rv0}; /* rev.b     */
      5'h0f:   shfl_5_mux = {src1_5_rv2, src1_5_rv3, src1_5_rv0, src1_5_rv1}; /* rev.h     */
      5'h1f:   shfl_5_mux = {src1_5_rv0, src1_5_rv1, src1_5_rv2, src1_5_rv3}; /* rev       */
      default: shfl_5_mux =  32'h0;
      endcase
    end

  assign shfl_5_out = (shfl_5_reg) ? shfl_5_mux : 32'h0;

  /*****************************************************************************************/
  /* pack                                                                                  */
  /*****************************************************************************************/
  always @ (imm_5_reg or opc_5_reg or src1_5_out or src2_5_out) begin
    case ({imm_5_reg[10], opc_5_reg[5]})
      2'b00:   pack_5_mux = {       src2_5_out[15:0],  src1_5_out[15:0] };    /* pack      */
      2'b10:   pack_5_mux = {       src2_5_out[31:16], src1_5_out[31:16]};    /* packu     */
      2'b01:   pack_5_mux = {16'h0, src2_5_out[7:0],   src1_5_out[7:0]  };    /* packh     */
      default: pack_5_mux =  32'h0;
      endcase
    end

  assign pack_5_out = (pack_5_reg) ? pack_5_mux : 32'h0;

  /*****************************************************************************************/
  /* single bit select                                                                     */
  /*****************************************************************************************/
  always @ (shamt_5_out) begin
    case (shamt_5_out[2:0])
      3'b000: byte_5_sel = 8'h01;
      3'b001: byte_5_sel = 8'h02;
      3'b010: byte_5_sel = 8'h04;
      3'b011: byte_5_sel = 8'h08;
      3'b100: byte_5_sel = 8'h10;
      3'b101: byte_5_sel = 8'h20;
      3'b110: byte_5_sel = 8'h40;
      3'b111: byte_5_sel = 8'h80;
      endcase
    end

  always @ (shamt_5_out or byte_5_sel) begin
    case (shamt_5_out[4:3])
      2'b00: bit_5_sel = {24'h0, byte_5_sel       };
      2'b01: bit_5_sel = {16'h0, byte_5_sel,  8'h0};
      2'b10: bit_5_sel = { 8'h0, byte_5_sel, 16'h0};
      2'b11: bit_5_sel = {       byte_5_sel, 24'h0};
      endcase
    end

  /*****************************************************************************************/
  /* main alu                                                                              */
  /*****************************************************************************************/
  assign alu_5_ain = (alta_5_reg) ?  {pc_5_reg, 1'b0} : src1_5_out;
  assign alu_5_bim = (bits_5_reg) ?  bit_5_sel        :
                     (altb_5_reg) ?  imm_5_reg        : src2_5_out;
  assign alu_5_bin = {32{invb_5_reg}} ^ alu_5_bim;

`ifdef INSTANCE_ADD
  inst_add ALU_ADD   ( .add_out(alu_5_add), .clk(clk), .add_ain(alu_5_ain),
                       .add_bin(alu_5_bin), .add_cyin(invb_5_reg) ); 
`else
  assign alu_5_add = alu_5_ain + alu_5_bin + invb_5_reg;
`endif

  assign alu_5_ext = sl_5_out | sr_5_out | rot_5_out | shfl_5_out | pack_5_out;
  assign alu_5_tst = (slt_5_reg && !br_5_ge) || (sltu_5_reg && !br_5_uge) ||
                     (sbext_5_reg && |(src1_5_out & bit_5_sel));

  always @ (a_add_5_reg or a_ain_5_reg or a_bin_5_reg or a_and_5_reg or a_ext_5_reg or
            a_or_5_reg or a_tst_5_reg or a_xor_5_reg or alu_5_add or alu_5_ain or
            alu_5_bin or alu_5_ext or alu_5_tst or invb_5_reg) begin
    casex ({a_ext_5_reg, a_tst_5_reg, a_xor_5_reg, a_and_5_reg,
            a_or_5_reg,  a_add_5_reg, a_bin_5_reg, a_ain_5_reg}) //synthesis parallel_case
      8'bxxxxxxx1: alu_5_out = alu_5_ain;                                     /* pass a    */
      8'bxxxxxx1x: alu_5_out = alu_5_bin;                                     /* pass b    */
      8'bxxxxx1xx: alu_5_out = alu_5_add;                                     /* add/sub   */
      8'bxxxx1xxx: alu_5_out = alu_5_ain | alu_5_bin;                         /* or        */
      8'bxxx1xxxx: alu_5_out = alu_5_ain & alu_5_bin;                         /* and       */
      8'bxx1xxxxx: alu_5_out = alu_5_ain ^ alu_5_bin;                         /* xor       */
      8'bx1xxxxxx: alu_5_out = {31'h0,     alu_5_tst};                        /* test      */
      8'b1xxxxxxx: alu_5_out = alu_5_ext;                                     /* external  */
      default:     alu_5_out = 32'h0;
      endcase
    end

  /*****************************************************************************************/
  /* branch tests                                                                          */
  /*****************************************************************************************/
`ifdef INSTANCE_SUB
  inst_sub BR_SUB    ( .sub_out(op_5_diff), .sub_cyout(br_5_cyout), .clk(clk),
                       .sub_ain(src1_5_out), .sub_bin(src2_5_out) ); 
`else
  assign op_5_diff  = src1_5_out - src2_5_out;
  assign br_5_cyout = !op_5_diff[32];
`endif

  assign br_5_ne   = |op_5_diff[31:0];
  assign br_5_ge   = (!(src1_5_out[31] ^  src2_5_out[31]) && !op_5_diff[31]) ||
                     ( !src1_5_out[31] && src2_5_out[31]);
  assign br_5_uge  = !br_5_ne || br_5_cyout;
  assign br_5_true = jal_5_reg ||
                     (br_5_reg[0] && !br_5_ne)  || (br_5_reg[1] && br_5_ne) ||
                     (br_5_reg[2] && !br_5_ge)  || (br_5_reg[3] && br_5_ge) ||
                     (br_5_reg[4] && !br_5_uge) || (br_5_reg[5] && br_5_uge);

  /*****************************************************************************************/
  /* exceptions                                                                            */
  /*****************************************************************************************/
  assign inst_5_ret  = valid_5_reg && run_exe;
  assign exc_5_req   = trap_5_reg || |irq_5_reg ||
                       (!debug_mode && (ecall_5_reg || ebrk_5_reg));
  assign flush_5_exc = valid_5_reg && (trap_5_reg || |irq_5_reg);
  assign vecti_5_req = |irq_5_reg[3:0] && (vmode_reg == 2'b01);

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      ebrk_inst <= 1'b0;
      eret_inst <= 1'b0;
      iack_int  <= 1'b0;
      iack_nmi  <= 1'b0;
      nmip_reg  <= 1'b0;
      wfi_reg   <= 1'b0;
      end
    else begin
      ebrk_inst <=  !debug_mode && inst_5_ret && ~|irq_5_reg    && ebrk_5_reg;
      eret_inst <=  !debug_mode && inst_5_ret && ~|irq_5_reg    && eret_5_reg;
      iack_int  <=  !debug_mode && inst_5_ret &&  !irq_5_reg[5] && |irq_5_reg[4:0];
      iack_nmi  <=  !debug_mode && inst_5_ret &&  !irq_5_reg[5] &&  irq_5_reg[4];
      nmip_reg  <= (!debug_mode && inst_5_ret &&   irq_5_reg[5]) ?  irq_5_reg[4] :
                    (nmi_5_reg || nmip_reg);
      wfi_reg   <= ~|irq_5_reg && ((wfi_5_reg && inst_5_ret) || wfi_reg);
      end
    end

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      dbg_type   <= 3'h0;
      debug_mode <= 1'b0;
      wfi_state  <= 1'b0;
      end
    else if (inst_5_ret) begin
      if (irq_5_reg[5]) dbg_type <= dbg_5_reg; 
      debug_mode <= !dret_5_reg && (irq_5_reg[5] || debug_mode);
      wfi_state  <= ~|irq_5_reg && (wfi_5_reg || wfi_state);
      end
    end

  /*****************************************************************************************/
  /* exception status                                                                      */
  /*****************************************************************************************/
  assign mcause_irq = (irq_5_reg[4]) ? `EC_NMI   :
                      (irq_5_reg[3]) ? mli_5_reg :
                      (irq_5_reg[2]) ? `EC_MEXTI :
                      (irq_5_reg[1]) ? `EC_MTMRI :
                      (irq_5_reg[0]) ? `EC_MSWI  :
                      (ecall_5_reg)  ? `EC_MCALL :
                      (ebrk_5_reg)   ? `EC_BREAK : `EC_ILLEG;

  assign except_wr = !debug_mode && inst_5_ret &&
                     (|irq_5_reg[4:0] || ecall_5_reg || ebrk_5_reg || trap_5_reg);

  assign mcause_wr = (csr_write && (csr_addr == `MCAUSE)) || except_wr;
  assign mepc_wr   = (csr_write && (csr_addr == `MEPC))   || except_wr;
  assign dpc_wr    = (csr_write && (csr_addr == `DPC) && debug_mode) ||
                     (!debug_mode && inst_5_ret && irq_5_reg[5]);

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      dpc_reg    <= 31'h0;
      mcause_reg <= `EC_NULL;
      mepc_reg   <= 31'h0;
      end
    else begin
      if (dpc_wr)    dpc_reg    <= (|runcsr_reg) ? csr_wdata[31:1] : pc_5_reg[31:1];
      if (mcause_wr) mcause_reg <= (|runcsr_reg) ? {csr_wdata[31], csr_wdata[5:0]} :
                                                    mcause_irq;
      if (mepc_wr)   mepc_reg   <= (|runcsr_reg) ? csr_wdata[31:1] : pc_5_reg[31:1];
      end
    end

  /*****************************************************************************************/
  /* control outputs                                                                       */
  /*****************************************************************************************/
  assign mtvec_addr = (debug_mode)   ? `DEX_VECT :
                      (irq_5_reg[5]) ? `DBG_VECT :
                      (irq_5_reg[4]) ? `NMI_VECT :
                      (vecti_5_req)  ? {mtvec_reg[31:8], mcause_irq[5:0], 2'b00} :
                                       {mtvec_reg, 2'b00};

  assign addr_out   = (exc_5_req)   ?  mtvec_addr      :
                      (flush_5_reg) ? {pc_4_reg, 1'b0} :
                      (dret_5_reg)  ? {dpc_reg,  1'b0} :
                      (eret_5_reg)  ? {mepc_reg, 1'b0} : alu_5_out;

  assign ld_pc      = valid_5_reg && (exc_5_req || br_5_true || flush_5_reg || dret_5_reg ||
                                     (!debug_mode && eret_5_reg));
  assign type_out   = opc_5_reg;
  assign ld_addr    = inst_5_ret && !exc_5_req && (ld_5_reg || st_5_reg || amo_5_reg);
  assign st_out     = st_5_reg;
  assign strt_5_csr = inst_5_ret && !exc_5_req && |csrop_5_reg[2:0];

  /*****************************************************************************************/
  /* csr interface                                                                         */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      csrdat_reg <= 32'h0;
      csr_read   <=  1'b0;
      csr_write  <=  1'b0;
      runcsr_reg <=  3'b0;
      end
    else if (mem_rdy_v) begin
      if (runcsr_reg[1]) csrdat_reg <= (csrop_6_reg[4]) ? csr_idata : csr_rdata;
      csr_read   <= runcsr_reg[2] && (|csrop_6_reg[1:0] || (csrop_6_reg[2] && |rd_6_reg));
      csr_write  <= runcsr_reg[1] && (csrop_6_reg[2] || (|csrop_6_reg[1:0] && rs1nz_6_reg));
      runcsr_reg <= {strt_5_csr, runcsr_reg[2:1]};
      end
    end

  assign csr_addr  = (|runcsr_reg) ? imm_6_reg : 12'h0;
  assign stall_csr = |runcsr_reg[2:1];

  always @ (runcsr_reg or csrop_6_reg or csrdat_reg or csrmod_6_reg) begin
    case ({runcsr_reg[0], csrop_6_reg[2:0]})
      4'b1001: csr_wdata =  csrmod_6_reg | csrdat_reg;
      4'b1010: csr_wdata = ~csrmod_6_reg & csrdat_reg;
      4'b1100: csr_wdata =  csrmod_6_reg;
      default: csr_wdata = 32'h0;
      endcase
    end

  /*****************************************************************************************/
  /* clock 6 - register write                                                              */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      alu_6_reg    <= 32'h0;
      amo_6_reg    <=  1'b0;
      csrmod_6_reg <= 32'h0;
      csrop_6_reg  <=  5'h0;
      imm_6_reg    <= 12'h0;
      jal_6_reg    <=  1'b0;
      ld_6_reg     <=  1'b0;
      rd_6_reg     <=  5'h0;
      retire_6_reg <=  1'b0;
      rs1nz_6_reg  <=  1'b0;
      s4byp1_reg   <=  1'b0;
      s4byp2_reg   <=  1'b0;
      s5byp1_reg   <=  1'b0;
      s5byp2_reg   <=  1'b0;
      valid_6_reg  <=  1'b0;
      wreg_6_reg   <=  1'b0;
      end
    else if (run_exe) begin
      alu_6_reg    <= alu_5_out;
      amo_6_reg    <= amo_5_reg;
      csrmod_6_reg <= csrop_5_reg[3] ? {27'h0, rs1_5_reg} : src1_5_out;
      csrop_6_reg  <= csrop_5_reg;
      imm_6_reg    <= imm_5_reg[11:0];
      jal_6_reg    <= jal_5_reg;
      ld_6_reg     <= ld_5_reg;
      rd_6_reg     <= rd_5_reg;
      retire_6_reg <= !(trap_5_reg || |irq_5_reg ||
                       (!debug_mode && (ecall_5_reg || ebrk_5_reg)));
      rs1nz_6_reg  <= |rs1_5_reg;
      s4byp1_reg   <= wreg_5_reg && ~|(rd_5_reg ^ rs1_3_addr);
      s4byp2_reg   <= wreg_5_reg && ~|(rd_5_reg ^ rs2_3_addr);
      s5byp1_reg   <= wreg_5_reg && ~|(rd_5_reg ^ rs1_4_reg) && |rd_5_reg;
      s5byp2_reg   <= wreg_5_reg && ~|(rd_5_reg ^ rs2_4_reg) && |rd_5_reg;
      valid_6_reg  <= !flush_5_exc && valid_5_reg;
      wreg_6_reg   <= wreg_5_reg;
      end
    end

  /*****************************************************************************************/
  /* control outputs                                                                       */
  /*****************************************************************************************/
  assign inst_ret   = valid_6_reg && run_exe && retire_6_reg;

  assign src1_4_byp = valid_6_reg && s4byp1_reg;
  assign src2_4_byp = valid_6_reg && s4byp2_reg;
  assign src1_5_byp = valid_6_reg && s5byp1_reg;
  assign src2_5_byp = valid_6_reg && s5byp2_reg;

  /*****************************************************************************************/
  /* register write interface                                                              */
  /*****************************************************************************************/
  assign dst_6_data = (jal_6_reg)             ? {pc_5_reg, 1'b0} :
                      (ld_6_reg || amo_6_reg) ? mem_rdat         :
                      (|csrop_6_reg[2:0])     ? csrdat_reg       : alu_6_reg;
  assign wr_6_en    = valid_6_reg && wreg_6_reg;

  endmodule
