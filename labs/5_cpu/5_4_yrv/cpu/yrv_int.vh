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
/** YRV interrupt control                                             Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module yrv_int (irq_bus, meip_reg, mli_code, mlip_reg, msip_reg, mtip_reg, clk, ei_req,
                iack_nmi, li_req, meie_reg, mie_reg, mlie_reg, msie_reg, mtie_reg, nmi_req,
                resetb, sw_req, timer_match, wfi_state);

  input         clk;                                       /* main cpu clock               */
  input         ei_req;                                    /* external int request         */
  input         iack_nmi;                                  /* iack: nmi                    */
  input         meie_reg;                                  /* machine ext int enable       */
  input         mie_reg;                                   /* master int enable            */
  input         msie_reg;                                  /* machine sw int enable        */
  input         mtie_reg;                                  /* mtimer_reg int enable        */
  input         nmi_req;                                   /* non-maskable interrupt       */
  input         resetb;                                    /* master reset                 */
  input         sw_req;                                    /* sw int request               */
  input         timer_match;                               /* timer/cmp match              */
  input         wfi_state;                                 /* waiting for interrupt        */
  input  [15:0] li_req;                                    /* local int requests           */
  input  [15:0] mlie_reg;                                  /* local int enable             */

  output        meip_reg;                                  /* machine ext int pending      */
  output        msip_reg;                                  /* machine sw int pending       */
  output        mtip_reg;                                  /* mtimer_reg int pending       */
  output  [4:0] irq_bus;                                   /* ireq nmi/li/ei/tmr/sw        */
  output  [6:0] mli_code;                                  /* mli highest pending          */
  output [15:0] mlip_reg;                                  /* local int pending            */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          int_enabl;                                 /* master int enable            */
  wire    [4:0] irq_bus;                                   /* irq dbg/rst/nmi/li/ei/tmr/sw */
  wire   [15:0] mli_pend;                                  /* masked int pending           */

  reg           meip_reg;                                  /* machine ext int pending      */
  reg           msip_reg;                                  /* machine sw int pending       */
  reg           mtip_reg;                                  /* mtimer_reg int pending       */
  reg           nmiip_reg;                                 /* nmi_req pending              */
  reg     [2:0] nmirq_reg;                                 /* nmi_req synchronizer         */
  reg     [6:0] mli_code;                                  /* li highest pending           */
  reg    [15:0] mlip_reg;                                  /* local int pending            */

  /*****************************************************************************************/
  /* interrupt pending                                                                     */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      meip_reg  <= 1'b0;
      msip_reg  <= 1'b0;
      mtip_reg  <= 1'b0;
      nmirq_reg <= 3'h0;
      nmiip_reg <= 1'b0;
      end
    else begin
      meip_reg  <= ei_req;
      msip_reg  <= sw_req;
      mtip_reg  <= timer_match;
      nmirq_reg <= {nmirq_reg[1:0], nmi_req};
      nmiip_reg <= (!nmirq_reg[2] && nmirq_reg[1]) || (!iack_nmi && nmiip_reg);
      end
    end

  /*****************************************************************************************/
  /* interrupt outputs                                                                     */
  /*****************************************************************************************/
  assign int_enabl  = mie_reg || wfi_state;
  assign irq_bus[0] = int_enabl && msip_reg && msie_reg;
  assign irq_bus[1] = int_enabl && mtip_reg && mtie_reg;
  assign irq_bus[2] = int_enabl && meip_reg && meie_reg;
  assign irq_bus[3] = int_enabl && |mli_pend;
  assign irq_bus[4] = nmiip_reg;

  /*****************************************************************************************/
  /* local interrupts                                                                      */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) mlip_reg <= 16'h0;
    else         mlip_reg <= li_req;
    end

  assign mli_pend = mlip_reg & mlie_reg;

  always @ (mli_pend) begin
    casex (mli_pend)
      16'bxxxxxxxxxxxxxxx1: mli_code = `EC_LI0;
      16'bxxxxxxxxxxxxxx10: mli_code = `EC_LI1;
      16'bxxxxxxxxxxxxx100: mli_code = `EC_LI2;
      16'bxxxxxxxxxxxx1000: mli_code = `EC_LI3;
      16'bxxxxxxxxxxx10000: mli_code = `EC_LI4;
      16'bxxxxxxxxxx100000: mli_code = `EC_LI5;
      16'bxxxxxxxxx1000000: mli_code = `EC_LI6;
      16'bxxxxxxxx10000000: mli_code = `EC_LI7;
      16'bxxxxxxx100000000: mli_code = `EC_LI8;
      16'bxxxxxx1000000000: mli_code = `EC_LI9;
      16'bxxxxx10000000000: mli_code = `EC_LI10;
      16'bxxxx100000000000: mli_code = `EC_LI11;
      16'bxxx1000000000000: mli_code = `EC_LI12;
      16'bxx10000000000000: mli_code = `EC_LI13;
      16'bx100000000000000: mli_code = `EC_LI14;
      16'b1000000000000000: mli_code = `EC_LI15;
      default:              mli_code = `EC_NULL;
      endcase
    end

  endmodule
