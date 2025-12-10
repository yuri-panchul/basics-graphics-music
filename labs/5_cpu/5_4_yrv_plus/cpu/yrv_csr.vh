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
/** YRV control/status registers                                      Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module yrv_csr (csr_idata, csr_ok_int, cycle_ov, ebrkd_reg, instret_ov, meie_reg, mie_reg,
                mlie_reg, msie_reg, mtie_reg, mtvec_reg, step_reg, timer_en, vmode_reg, clk,
                csr_achk, csr_addr, csr_read, csr_wdata, csr_write, dbg_type, debug_mode,
                dpc_reg, dresetb, eret_inst, hw_id, iack_int, inst_ret, mcause_reg, meip_reg,
                mepc_reg, mlip_reg, msip_reg, mtip_reg, nmip_reg, resetb, timer_rdata);

  input         clk;                                       /* cpu clock                    */
  input         csr_read;                                  /* csr read enable              */
  input         csr_write;                                 /* csr write enable             */
  input         debug_mode;                                /* in debug mode                */
  input         dresetb;                                   /* debug reset                  */
  input         eret_inst;                                 /* eret instruction             */
  input         iack_int;                                  /* iack: nmi/li/ei/tmr/sw       */
  input         inst_ret;                                  /* inst retired                 */
  input         meip_reg;                                  /* machine ext int pending      */
  input         msip_reg;                                  /* machine sw int pending       */
  input         mtip_reg;                                  /* machine tmr int pending      */
  input         nmip_reg;                                  /* nmi pending in debug mode    */
  input         resetb;                                    /* master reset                 */
  input   [2:0] dbg_type;                                  /* debug cause                  */
  input   [6:0] mcause_reg;                                /* exception cause              */
  input   [9:0] hw_id;                                     /* hardware id                  */
  input  [11:0] csr_achk;                                  /* csr address to check         */
  input  [11:0] csr_addr;                                  /* csr address                  */
  input  [15:0] mlip_reg;                                  /* local int pending            */
  input  [31:0] csr_wdata;                                 /* csr write data               */
  input  [31:1] dpc_reg;                                   /* debug pc                     */
  input  [31:1] mepc_reg;                                  /* exception pc                 */
  input  [63:0] timer_rdata;                               /* timer read data              */

  output        csr_ok_int;                                /* valid internal csr addr      */
  output        cycle_ov;                                  /* mcycle_reg ov                */
  output        ebrkd_reg;                                 /* ebreak causes debug          */
  output        instret_ov;                                /* minstret_reg ov              */
  output        meie_reg;                                  /* machine ext int enable       */
  output        mie_reg;                                   /* int enable                   */
  output        msie_reg;                                  /* machine sw int enable        */
  output        mtie_reg;                                  /* machine tmr int enable       */
  output        step_reg;                                  /* single-step                  */
  output        timer_en;                                  /* timer enable                 */
  output  [1:0] vmode_reg;                                 /* interrupt vector mode        */
  output [15:0] mlie_reg;                                  /* local int enable             */
  output [31:0] csr_idata;                                 /* csr internal read data       */
  output [31:2] mtvec_reg;                                 /* trap vector base             */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          ccount_en;                                 /* counter enable               */
  wire          dcsr_wr,    dscr0_wr,    dscr1_wr;         /* debug csr write strobes      */
  wire          icount_en;                                 /* inst ret count enable        */
  wire          mie_wr,     mcinh_wr,    mscr_wr;          /* csr write strobes            */
  wire          mstat_wr,   mtvec_wr;
  wire          timer_en;                                  /* timer enable                 */

  reg           csr_ok_int;                                /* valid internal csr addr      */
  reg           ebrkd_reg;                                 /* ebreak causes debug mode     */
  reg           mcyinh_reg;                                /* cycle inhibit                */
  reg           meie_reg;                                  /* machine ext int en           */
  reg           mie_reg,    mpie_reg;                      /* int enable stack             */
  reg           mirinh_reg;                                /* inst ret inhibit             */
  reg           msie_reg;                                  /* machine sw int en            */
  reg           mtie_reg;                                  /* machine tmr int en           */
  reg           step_reg;                                  /* single-step                  */
  reg           stopc_reg,  stopt_reg;                     /* stop cnt/tmr                 */
  reg     [1:0] vmode_reg;                                 /* vectored interrupt mode      */
  reg    [15:0] mlie_reg;                                  /* machine local int            */
  reg    [31:0] csr_idata;                                 /* csr internal read data       */
  reg    [31:0] dscratch0_reg;                             /* debug scratch 0              */
  reg    [31:0] dscratch1_reg;                             /* debug scratch 1              */
  reg    [31:0] mscratch_reg;                              /* machine scratch              */
  reg    [31:2] mtvec_reg;                                 /* machine trap vector          */

  /*****************************************************************************************/
  /* cycle counter signal declarations                                                     */
  /*****************************************************************************************/
`ifdef CYCCNT_0
  wire          cycle_ov;
  wire   [31:0] cycle_reg;
  wire   [31:0] cycleh_reg;
`else
  wire          mcycle_wr;                                 /* mcycle write strobe          */
  wire          ld_mcycle;                                 /* mcycle load                  */
  wire   [31:0] cycle_nxt;
  reg    [31:0] cycle_reg;
`ifdef CYCCNT_32
  wire   [31:0] cycleh_reg;
  reg           cycle_ov;
`else
  wire          cycle_ov;
  wire          mcycleh_wr;                                /* mcycleh write strobe         */
  wire          ld_mcycleh;                                /* mcycleh load                 */
  wire   [31:0] cycleh_nxt;
  reg    [31:0] cycleh_reg;
`endif  // CYCCNT_32
`endif  // CYC_CNT_0

  /*****************************************************************************************/
  /* instructions-retired counter signal declarations                                      */
  /*****************************************************************************************/
`ifdef INSTRET_0
  wire          instret_ov;
  wire   [31:0] instret_reg, instreth_reg;
`else
  wire          minstret_wr;                               /* instret write strobe         */
  wire          ld_minstret;                               /* instret load                 */
  wire   [31:0] instret_nxt;
  reg    [31:0] instret_reg;                               /* inst retired counter         */
`ifdef INSTRET_32
  wire   [31:0] instreth_reg;
  reg           instret_ov;
`else
  wire          instret_ov;
  wire          minstreth_wr;                              /* instreth write strobe        */
  wire          ld_minstreth;                              /* instreth load                */
  wire   [31:0] instreth_nxt;
  reg    [31:0] instreth_reg;
`endif  // INSTRET_32
`endif  // INSTRET_0

  /*****************************************************************************************/
  /* valid address check                                                                   */
  /*****************************************************************************************/
  always @ (csr_achk or debug_mode) begin
    case (csr_achk)
      `DCSR,
      `DPC,
      `DSCRATCH0,
      `DSCRATCH1:     csr_ok_int = debug_mode;
      `TIME,
      `TIMEH,
      `MSTATUS,
      `MIE,
      `MTVEC,
      `MSCRATCH,
      `MEPC,
      `MCAUSE,
      `MTVAL,
      `MIP,
`ifdef CYCCNT_0
`else
      `CYCLE,
      `MCYCLE,
`ifdef CYCCNT_32
`else
      `CYCLEH,
      `MCYCLEH,
`endif  //CYCCNT_32
`endif  //CYCCNT_0
`ifdef INSTRET_0
`else
      `INSTRET,
      `MINSTRET,
`ifdef INSTRET_32
`else
      `INSTRETH,
      `MINSTRETH,
`endif  //INSTRET_32
`endif  //INSTRET_0
      `MISA,
      `MVENDORID,
      `MARCHID,
      `MIMPID,
      `MHARTID,
      `MCOUNTINHIBIT: csr_ok_int = 1'b1;
      default:        csr_ok_int = 1'b0;
      endcase
    end

  /*****************************************************************************************/
  /* control/status registers                                                              */
  /*****************************************************************************************/
  assign mcinh_wr = csr_write && (csr_addr == `MCOUNTINHIBIT);
  assign mie_wr   = csr_write && (csr_addr == `MIE);
  assign mscr_wr  = csr_write && (csr_addr == `MSCRATCH);
  assign mstat_wr = csr_write && (csr_addr == `MSTATUS);
  assign mtvec_wr = csr_write && (csr_addr == `MTVEC);

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      mcyinh_reg   <=  1'b0;
      mirinh_reg   <=  1'b0;
      mie_reg      <=  1'b0;
      mpie_reg     <=  1'b1;
      mlie_reg     <= 16'h0;
      meie_reg     <=  1'b0;
      msie_reg     <=  1'b0;
      mtie_reg     <=  1'b0;
      mscratch_reg <= `MSCR_RST;
      mtvec_reg    <= `MTVEC_RST;
      vmode_reg    <= 2'h0;
      end
    else begin
      if (mcinh_wr) begin
        mcyinh_reg <= csr_wdata[0];
        mirinh_reg <= csr_wdata[2];
        end
      if (mstat_wr || iack_int || eret_inst) begin
        mie_reg   <= (mstat_wr) ? csr_wdata[3] :
                     (iack_int) ? 1'b0         : mpie_reg;
        mpie_reg  <= (mstat_wr) ? csr_wdata[7] :
                     (iack_int) ? mie_reg      : 1'b1;
        end
      if (mie_wr) begin
        mlie_reg  <= csr_wdata[31:16];
        meie_reg  <= csr_wdata[11];
        mtie_reg  <= csr_wdata[7];
        msie_reg  <= csr_wdata[3];
        end
      if (mscr_wr) mscratch_reg <= csr_wdata;
      if (mtvec_wr) begin
        mtvec_reg <= csr_wdata[31:2];
        vmode_reg <= csr_wdata[1:0];
        end
      end
    end

  /*****************************************************************************************/
  /* debug control/status registers                                                        */
  /*****************************************************************************************/
  assign timer_en    = !(debug_mode && stopt_reg);
  assign dcsr_wr     = csr_write && (csr_addr == `DCSR);
  assign dscr0_wr    = csr_write && (csr_addr == `DSCRATCH0);
  assign dscr1_wr    = csr_write && (csr_addr == `DSCRATCH1);

  always @ (posedge clk or negedge dresetb) begin
    if (!dresetb) begin
      ebrkd_reg     <=  1'b0;
      stopc_reg     <=  1'b0;
      stopt_reg     <=  1'b0;
      step_reg      <=  1'b0;
      dscratch0_reg <= 32'h0;
      dscratch1_reg <= 32'h0;
      end
    else begin
      if (dcsr_wr) begin
        ebrkd_reg  <= csr_wdata[15];
        stopc_reg  <= csr_wdata[10];
        stopt_reg  <= csr_wdata[9];
        step_reg   <= csr_wdata[2];
        end
      if (dscr0_wr) dscratch0_reg <= csr_wdata;
      if (dscr1_wr) dscratch1_reg <= csr_wdata;
      end
    end

  /*****************************************************************************************/
  /* csr read data                                                                         */
  /*****************************************************************************************/
  always @ (csr_addr or cycle_reg or cycleh_reg or dbg_type or dpc_reg or dscratch0_reg or
            dscratch1_reg or ebrkd_reg or hw_id or instret_reg or instreth_reg or
            mcause_reg or mcyinh_reg or meie_reg or meip_reg or mepc_reg or mie_reg or
            mirinh_reg or mlie_reg or mlip_reg or mpie_reg or mscratch_reg or msie_reg or
            msip_reg or mtie_reg or mtip_reg or mtvec_reg or nmip_reg or step_reg or
            stopc_reg or stopt_reg or timer_rdata or vmode_reg) begin
    case (csr_addr)
      `CYCLE,
      `MCYCLE:        csr_idata = cycle_reg;
      `CYCLEH,
      `MCYCLEH:       csr_idata = cycleh_reg;
      `DCSR:          csr_idata = {`XDEBUGVER, 12'h0, ebrkd_reg, 4'h0, stopc_reg,
                                   stopt_reg, dbg_type, 2'h0, nmip_reg, step_reg, 2'h3};
      `DPC:           csr_idata = {dpc_reg, 1'b0};
      `DSCRATCH0:     csr_idata = dscratch0_reg;
      `DSCRATCH1:     csr_idata = dscratch1_reg;
      `INSTRET,
      `MINSTRET:      csr_idata = instret_reg;
      `INSTRETH,
      `MINSTRETH:     csr_idata = instreth_reg;
      `MARCHID:       csr_idata = `MARCHID_DEF;
      `MCAUSE:        csr_idata = {mcause_reg[6], 25'h0, mcause_reg[5:0]};
      `MISA:          csr_idata = `MISA_DEF;
      `MEPC:          csr_idata = {mepc_reg, 1'b0};
      `MHARTID:       csr_idata = {22'h0, hw_id};
      `MIE:           csr_idata = {mlie_reg,
                                   4'h0, meie_reg, 3'h0, mtie_reg, 3'h0, msie_reg, 3'h0};
      `MIMPID:        csr_idata = `MIMPID_DEF;
      `MIP:           csr_idata = {mlip_reg,
                                   4'h0, meip_reg, 3'h0, mtip_reg, 3'h0, msip_reg, 3'h0};
      `MSCRATCH:      csr_idata = mscratch_reg;
      `MSTATUS:       csr_idata = {24'h000018, mpie_reg, 3'h0, mie_reg, 3'h0};
      `MCOUNTINHIBIT: csr_idata = {29'h0, mirinh_reg, 1'b0, mcyinh_reg};
      `MTVEC:         csr_idata = {mtvec_reg, vmode_reg};
      `MVENDORID:     csr_idata = `MVENDORID_DEF;
      `TIME:          csr_idata = timer_rdata[31:0];
      `TIMEH:         csr_idata = timer_rdata[63:32];
      default:        csr_idata = 32'h0;
      endcase
    end

  /*****************************************************************************************/
  /* cycle counter                                                                         */
  /*****************************************************************************************/
  assign ccount_en  = !(debug_mode && stopc_reg) && !mcyinh_reg;

`ifdef CYCCNT_0
  assign cycle_ov   =  1'b0;
  assign cycle_reg  = 32'h0;
  assign cycleh_reg = 32'h0;

`else
  assign mcycle_wr  = csr_write && (csr_addr == `MCYCLE);
  assign ld_mcycle  = mcycle_wr || ccount_en;

`ifdef INSTANCE_CNT
  inst_cnt CCYC_CNTL ( .cnt_out(cycle_nxt), .clk(clk), .cnt_in(cycle_reg) ); 
`else
  assign cycle_nxt[7:0]   = cycle_reg[7:0]   + 1'b1;
  assign cycle_nxt[15:8]  = cycle_reg[15:8]  + &cycle_reg[7:0];
  assign cycle_nxt[23:16] = cycle_reg[23:16] + &cycle_reg[15:0];
  assign cycle_nxt[31:24] = cycle_reg[31:24] + &cycle_reg[23:0];
`endif

  always @ (posedge clk or negedge resetb) begin
    if        (!resetb) cycle_reg <= 32'h0;
    else if (ld_mcycle) cycle_reg <= (mcycle_wr) ? csr_wdata : cycle_nxt;
    end

`ifdef CYCCNT_32
  assign cycleh_reg = 32'h0;

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) cycle_ov <= 1'b0;
    else         cycle_ov <= !mcycle_wr && ccount_en && &cycle_reg;
    end

`else
  assign cycle_ov   =  1'b0;
  assign mcycleh_wr = csr_write && (csr_addr == `MCYCLEH);
  assign ld_mcycleh = mcycleh_wr || (ccount_en && &cycle_reg);

`ifdef INSTANCE_CNT
  inst_cnt CCYC_CNTH ( .cnt_out(cycleh_nxt), .clk(clk), .cnt_in(cycleh_reg) ); 
`else
  assign cycleh_nxt[7:0]   = cycleh_reg[7:0]   + 1'b1;
  assign cycleh_nxt[15:8]  = cycleh_reg[15:8]  + &cycleh_reg[7:0];
  assign cycleh_nxt[23:16] = cycleh_reg[23:16] + &cycleh_reg[15:0];
  assign cycleh_nxt[31:24] = cycleh_reg[31:24] + &cycleh_reg[23:0];
`endif

  always @ (posedge clk or negedge resetb) begin
    if         (!resetb) cycleh_reg <= 32'h0;
    else if (ld_mcycleh) cycleh_reg <= (mcycleh_wr) ? csr_wdata : cycleh_nxt;
    end

`endif  //CYCCNT_32
`endif  //CYCCNT_0

  /*****************************************************************************************/
  /* instructions-retired counter                                                          */
  /*****************************************************************************************/
  assign icount_en    = inst_ret && !(debug_mode && stopc_reg) && !mirinh_reg;

`ifdef INSTRET_0
  assign instret_ov   =  1'b0;
  assign instret_reg  = 32'h0;
  assign instreth_reg = 32'h0;

`else
  assign minstret_wr  = csr_write && (csr_addr == `MINSTRET);
  assign ld_minstret  = minstret_wr  || icount_en;

`ifdef INSTANCE_CNT
  inst_cnt INST_CNTL ( .cnt_out(instret_nxt), .clk(clk), .cnt_in(instret_reg) ); 
`else
  assign instret_nxt[7:0]   = instret_reg[7:0]   + 1'b1;
  assign instret_nxt[15:8]  = instret_reg[15:8]  + &instret_reg[7:0];
  assign instret_nxt[23:16] = instret_reg[23:16] + &instret_reg[15:0];
  assign instret_nxt[31:24] = instret_reg[31:24] + &instret_reg[23:0];
`endif

  always @ (posedge clk or negedge resetb) begin
    if          (!resetb) instret_reg <= 32'h0;
    else if (ld_minstret) instret_reg <= (minstret_wr) ? csr_wdata : instret_nxt;
    end

`ifdef INSTRET_32
  assign instreth_reg = 32'h0;

  always @ (posedge clk or negedge resetb) begin
    if (!resetb) instret_ov <= 1'b0;
    else         instret_ov <= !minstret_wr && icount_en && &instret_reg;
    end

`else
  assign instret_ov   = 1'b0;
  assign minstreth_wr = csr_write && (csr_addr == `MINSTRETH);
  assign ld_minstreth = minstreth_wr || (icount_en && &instret_reg);

`ifdef INSTANCE_CNT
  inst_cnt INST_CNTL ( .cnt_out(instreth_nxt), .clk(clk), .cnt_in(instreth_reg) ); 
`else
  assign instreth_nxt[7:0]   = instreth_reg[7:0]   + 1'b1;
  assign instreth_nxt[15:8]  = instreth_reg[15:8]  + &instreth_reg[7:0];
  assign instreth_nxt[23:16] = instreth_reg[23:16] + &instreth_reg[15:0];
  assign instreth_nxt[31:24] = instreth_reg[31:24] + &instreth_reg[23:0];
`endif

  always @ (posedge clk or negedge resetb) begin
    if           (!resetb) instreth_reg <= 32'h0;
    else if (ld_minstreth) instreth_reg <= (minstreth_wr) ? csr_wdata : instreth_nxt;
    end

`endif  //INSTRET_32
`endif  //INSTRET_0

  endmodule
