/*******************************************************************************************/
/**                                                                                       **/
/** Copyright 2020 Monte J. Dalrymple                                                     **/
/**                                                                                       **/
/** Modified by Yuri Panchul in 2023-2025                                                 **/
/** to integrate into Basics-Graphics-Music (BGM) project                                 **/
/** from Verilog Meetup.                                                                  **/
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
/** YRV top level                                                     Rev 0.0  03/29/2020 **/
/**                                                                                       **/
/*******************************************************************************************/

/* options                                                                                 */
`include "yrv_opt.vh"
/* instruction opcodes                                                                     */
`include "define_dec.vh"
/* standard csr addresses                                                                  */
`include "define_csr.vh"
/* exception codes                                                                         */
`include "define_ec.vh"
/* control/status registers                                                                */

`include "yrv_csr.vh"
/* interrupt control                                                                       */
`include "yrv_int.vh"
/* cpu                                                                                     */
`include "yrv_cpu.vh"

`ifdef INSTANCE_REG
/* instantiated registers                                                                  */
`include "inst_reg.vh"
`endif
`ifdef INSTANCE_ADD
/* instantiated adder                                                                      */
`include "inst_add.vh"
`endif
`ifdef INSTANCE_SUB
/* instantiated subtractor                                                                 */
`include "inst_sub.vh"
`endif
`ifdef INSTANCE_INC
/* instantiated incrementer                                                                */
`include "inst_inc.vh"
`endif
`ifdef INSTANCE_CNT
/* instantiated count increment                                                            */
`include "inst_cnt.vh"
`endif

module yrv_top  (csr_achk, csr_addr, csr_read, csr_wdata, csr_write, debug_mode, ebrk_inst,
                 mem_addr, mem_ble, mem_lock, mem_trans, mem_wdata, mem_write, timer_en,
                 wfi_state, brk_req, bus_32, clk, csr_ok_ext, csr_rdata, dbg_req, dresetb,
                 ei_req, halt_reg, hw_id, li_req, mem_rdata, mem_ready, nmi_req, resetb,
                 sw_req, timer_match, timer_rdata);

  input         brk_req;                                   /* breakpoint request           */
  input         bus_32;                                    /* 32-bit bus select            */
  input         clk;                                       /* cpu clock                    */
  input         csr_ok_ext;                                /* valid external csr addr      */
  input         dbg_req;                                   /* debug request                */
  input         dresetb;                                   /* debug reset                  */
  input         ei_req;                                    /* external int request         */
  input         halt_reg;                                  /* halt (enter debug)           */
  input         mem_ready;                                 /* memory ready                 */
  input         nmi_req;                                   /* non-maskable interrupt       */
  input         resetb;                                    /* master reset                 */
  input         sw_req;                                    /* sw int request               */
  input         timer_match;                               /* timer/cmp match              */
  input   [9:0] hw_id;                                     /* hardware id                  */
  input  [15:0] li_req;                                    /* local int requests           */
  input  [31:0] csr_rdata;                                 /* csr external read data       */
  input  [31:0] mem_rdata;                                 /* memory read data             */
  input  [63:0] timer_rdata;                               /* timer read data              */

  output        csr_read;                                  /* csr read enable              */
  output        csr_write;                                 /* csr write enable             */
  output        debug_mode;                                /* in debug mode                */
  output        ebrk_inst;                                 /* ebreak instruction           */
  output        mem_lock;                                  /* memory lock (rmw)            */
  output        mem_write;                                 /* memory write enable          */
  output        timer_en;                                  /* timer enable                 */
  output        wfi_state;                                 /* waiting for interrupt        */
  output  [1:0] mem_trans;                                 /* memory transfer type         */
  output  [3:0] mem_ble;                                   /* memory byte lane enables     */
  output [11:0] csr_achk;                                  /* csr address to check         */
  output [11:0] csr_addr;                                  /* csr address                  */
  output [31:0] csr_wdata;                                 /* csr write data               */
  output [31:0] mem_addr;                                  /* memory address               */
  output [31:0] mem_wdata;                                 /* memory write data            */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          csr_read;                                  /* csr read enable              */
  wire          csr_ok_int;                                /* valid internal csr addr      */
  wire          csr_write;                                 /* csr write enable             */
  wire          cycle_ov;                                  /* mcycle_reg ov              ! */
  wire          dbg_req;                                   /* debug request                */
  wire          debug_mode;                                /* in debug mode                */
  wire          ebrk_inst;                                 /* ebreak instruction output  ! */
  wire          ebrkd_reg;                                 /* ebreak causes debug          */
  wire          eret_inst;                                 /* eret instruction             */
  wire          halt_reg;                                  /* halt (enter debug)           */
  wire          iack_int;                                  /* iack: nmi/li/ei/tmr/sw       */
  wire          iack_nmi;                                  /* iack: nmi                    */
  wire          inst_ret;                                  /* inst retired                 */
  wire          instret_ov;                                /* minstret_reg ov            ! */
  wire          mem_lock;                                  /* memory lock (rmw)            */
  wire          mem_write;                                 /* memory write enable          */
  wire          meie_reg,    meip_reg;                     /* machine ext int              */
  wire          mie_reg;                                   /* master int enable            */
  wire          msie_reg,    msip_reg;                     /* machine sw int               */
  wire          mtie_reg,    mtip_reg;                     /* machine tmr int              */
  wire          nmip_reg;                                  /* nmi pending in debug mode    */
  wire          step_reg;                                  /* single-step                  */
  wire          timer_en;                                  /* timer enable                 */
  wire          wfi_state;                                 /* waiting for interrupt        */
  wire    [1:0] mem_trans;                                 /* memory transfer type         */
  wire    [1:0] vmode_reg;                                 /* vectored interrupt mode      */
  wire    [2:0] dbg_type;                                  /* debug cause                  */
  wire    [3:0] mem_ble;                                   /* memory byte lane enables     */
  wire    [4:0] irq_bus;                                   /* irq: nmi/li/ei/tmr/sw        */
  wire    [6:0] mcause_reg;                                /* exception cause              */
  wire    [6:0] mli_code;                                  /* mli highest pending          */
  wire   [11:0] csr_achk;                                  /* csr address to check         */
  wire   [11:0] csr_addr;                                  /* csr address                  */
  wire   [15:0] mlie_reg;                                  /* local int enable             */
  wire   [15:0] mlip_reg;                                  /* local int pending            */
  wire   [31:0] csr_idata;                                 /* csr internal read data       */
  wire   [31:0] csr_rdata;                                 /* csr external read data       */
  wire   [31:0] csr_wdata;                                 /* csr write data               */
  wire   [31:1] dpc_reg;                                   /* debug pc                     */
  wire   [31:0] mem_addr;                                  /* memory address               */
  wire   [31:0] mem_wdata;                                 /* memory write data            */
  wire   [31:1] mepc_reg;                                  /* exception pc                 */
  wire   [31:2] mtvec_reg;                                 /* trap vector base             */

  /*****************************************************************************************/
  /* cpu                                                                                   */
  /*****************************************************************************************/
  yrv_cpu CPU  ( .csr_achk(csr_achk), .csr_addr(csr_addr), .csr_read(csr_read),
                 .csr_wdata(csr_wdata), .csr_write(csr_write), .dbg_type(dbg_type),
                 .debug_mode(debug_mode), .dpc_reg(dpc_reg), .ebrk_inst(ebrk_inst),
                 .eret_inst(eret_inst), .iack_int(iack_int), .iack_nmi(iack_nmi),
                 .inst_ret(inst_ret), .mcause_reg(mcause_reg), .mem_addr(mem_addr),
                 .mem_ble(mem_ble), .mem_lock(mem_lock), .mem_trans(mem_trans),
                 .mem_wdata(mem_wdata), .mem_write(mem_write), .mepc_reg(mepc_reg),
                 .nmip_reg(nmip_reg), .wfi_state(wfi_state), .brk_req(brk_req),
                 .bus_32(bus_32), .clk(clk), .csr_idata(csr_idata), .csr_rdata(csr_rdata),
                 .csr_ok_ext(csr_ok_ext), .csr_ok_int(csr_ok_int), .dbg_req(dbg_req),
                 .ebrkd_reg(ebrkd_reg), .halt_reg(halt_reg), .irq_bus(irq_bus),
                 .mem_rdata(mem_rdata), .mem_ready(mem_ready), .mli_code(mli_code),
                 .mtvec_reg(mtvec_reg), .resetb(resetb), .step_reg(step_reg),
                 .vmode_reg(vmode_reg) );

  /*****************************************************************************************/
  /* control/status registers                                                              */
  /*****************************************************************************************/
  yrv_csr CSR  ( .csr_idata(csr_idata), .csr_ok_int(csr_ok_int), .cycle_ov(cycle_ov),
                 .ebrkd_reg(ebrkd_reg), .instret_ov(instret_ov), .meie_reg(meie_reg),
                 .mie_reg(mie_reg), .mlie_reg(mlie_reg), .msie_reg(msie_reg),
                 .mtie_reg(mtie_reg), .mtvec_reg(mtvec_reg), .step_reg(step_reg),
                 .timer_en(timer_en), .vmode_reg(vmode_reg), .clk(clk), .csr_achk(csr_achk),
                 .csr_addr(csr_addr), .csr_read(csr_read), .csr_wdata(csr_wdata),
                 .csr_write(csr_write), .dbg_type(dbg_type), .debug_mode(debug_mode),
                 .dpc_reg(dpc_reg), .dresetb(dresetb), .eret_inst(eret_inst), .hw_id(hw_id),
                 .iack_int(iack_int), .inst_ret(inst_ret), .mcause_reg(mcause_reg),
                 .meip_reg(meip_reg), .mepc_reg(mepc_reg), .mlip_reg(mlip_reg),
                 .msip_reg(msip_reg), .mtip_reg(mtip_reg), .nmip_reg(nmip_reg),
                 .resetb(resetb), .timer_rdata(timer_rdata) );

  /*****************************************************************************************/
  /* interrupt control                                                                     */
  /*****************************************************************************************/
  yrv_int INT  ( .irq_bus(irq_bus), .meip_reg(meip_reg), .mli_code(mli_code),
                 .mlip_reg(mlip_reg), .msip_reg(msip_reg), .mtip_reg(mtip_reg), .clk(clk),
                 .ei_req(ei_req), .iack_nmi(iack_nmi), .li_req(li_req), .meie_reg(meie_reg),
                 .mie_reg(mie_reg), .mlie_reg(mlie_reg),  .msie_reg(msie_reg),
                 .mtie_reg(mtie_reg), .nmi_req(nmi_req), .resetb(resetb), .sw_req(sw_req),
                 .timer_match(timer_match), .wfi_state(wfi_state) );

  endmodule
