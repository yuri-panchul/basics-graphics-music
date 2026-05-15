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
/** serial receiver module (async/sync)                               Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module serial_rx (bufr_ovr, bufr_full, rx_rdata, rx_run, auto_trig, cks_mode, clkp,
                  rd_rdata, rx_sync, s_reset, ser_rxd);

  input         auto_trig;                                 /* clocked serial trigger       */
  input         cks_mode;                                  /* clocked serial mode          */
  input         clkp;                                      /* main peripheral clock        */
  input         rd_rdata;                                  /* read rx data register        */
  input         rx_sync;                                   /* receiver clock enable        */
  input         s_reset;                                   /* synchronous reset            */
  input         ser_rxd;                                   /* receive data input           */

  output        bufr_ovr;                                  /* receive buffer overrun       */
  output        bufr_full;                                 /* receive buffer full flag     */
  output        rx_run;                                    /* receive is running           */
  output  [7:0] rx_rdata;                                  /* receive data buffer          */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire        abort_dec;                                   /* start bit too short (async)  */
  wire        brk_end;                                     /* end of break detected        */
  wire        brk_strt;                                    /* recognized break             */
  wire        idleb_dec;                                   /* idle line detect (async)     */
  wire        ld_bufr;                                     /* buffer load enables          */
  wire        ld_shft;                                     /* shifter load enable          */
  wire        loadclk;                                     /* data load clock (async)      */
  wire        smplclk;                                     /* data sample clock (async)    */

  reg         bitclk_reg;                                  /* rx bit clock                 */
  reg         bufr_full;                                   /* buffer full flag             */
  reg         bufr_ovr;                                    /* buffer overrun output        */
  reg         falsest_reg;                                 /* false start check disable    */
  reg         rdata_reg;                                   /* sampled data input (async)   */
  reg         rddly_reg;                                   /* delayed sampled data (async) */
  reg         running_reg;                                 /* receiving byte (async)       */
  reg         rx_run;                                      /* cks running                  */
  reg         rx_strt;                                     /* cks start                    */
  reg         rxbrk_reg;                                   /* receiving break (async)      */
  reg         stop_reg;                                    /* stop bit (async)             */
  reg         sync_dly;                                    /* cks sync delayed             */
  reg   [3:0] divider_nxt, divider_reg;                    /* clock divider (async)        */
  reg   [7:0] rx_rdata;                                    /* receive data buffer          */
  reg   [9:0] shft_nxt, shft_reg;                          /* rx shifter                   */

  /*****************************************************************************************/
  /* serial receiver control signals                                                       */
  /*****************************************************************************************/
  assign brk_end   = rxbrk_reg && !stop_reg;
  assign brk_strt  = !cks_mode && &shft_reg && stop_reg && rddly_reg;
  assign smplclk   = !bitclk_reg && divider_reg[3] && !divider_reg[2];
  assign loadclk   = bitclk_reg && !divider_reg[3] && !divider_reg[2] && !divider_reg[0];
  assign abort_dec = !falsest_reg && !rddly_reg && smplclk;
  assign idleb_dec = !abort_dec && running_reg && !shft_reg[0] && !brk_end;
  assign ld_shft   = rx_sync && (!idleb_dec || smplclk || cks_mode);

  always @ (cks_mode or idleb_dec or rx_run or rx_strt or ser_rxd or shft_reg or
            stop_reg) begin
    casex ({cks_mode, idleb_dec, rx_strt, rx_run})
      4'b01xx: shft_nxt = {1'b1, stop_reg,  shft_reg[8:1]};
      4'b1x01: shft_nxt = {1'b0, !ser_rxd, shft_reg[8:1]};
      4'b1x11: shft_nxt = {1'b0, !ser_rxd, 8'b10000000  };
      default: shft_nxt = {1'b0, 1'b0,      8'b00000000  };
      endcase
    end

  /*****************************************************************************************/
  /* serial receiver buffer and status                                                     */
  /*****************************************************************************************/
  assign ld_bufr  = (shft_reg[0] && (sync_dly || (rx_sync && loadclk && !rxbrk_reg))) ||
                    (rx_sync && brk_end) || s_reset;

  always @ (posedge clkp) begin
    bufr_full <= !s_reset && (ld_bufr || (!rd_rdata && bufr_full));
    if (ld_bufr) rx_rdata <= (cks_mode) ? {!shft_reg[1], !shft_reg[2], !shft_reg[3],
                                           !shft_reg[4], !shft_reg[5], !shft_reg[6],
                                           !shft_reg[7], !shft_reg[8]} : ~shft_reg[8:1];
    if (ld_bufr || rd_rdata) bufr_ovr <= !s_reset && ld_bufr && bufr_full && !rd_rdata;
    end

  /*****************************************************************************************/
  /* serial receiver shifter (inverted data)                                               */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    if (ld_shft || s_reset) begin
      falsest_reg <= !s_reset && idleb_dec;
      rxbrk_reg   <= !s_reset && stop_reg && (rxbrk_reg || brk_strt);
      stop_reg    <= !s_reset && running_reg && rddly_reg;
      shft_reg    <= (s_reset) ? 10'h000 : shft_nxt;
      end
    end

  /*****************************************************************************************/
  /* clock divider                                                                         */
  /*****************************************************************************************/
  always @ (divider_reg or running_reg) begin
    casex ({running_reg, divider_reg})
      5'b0xxxx,
      5'b110xx: divider_nxt = 4'b0000;
      5'b10000: divider_nxt = 4'b0001;
      default:  divider_nxt = {divider_reg[2:0], !divider_reg[3]};
      endcase
    end

  /*****************************************************************************************/
  /* async state machine                                                                   */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    if (rx_sync || s_reset) begin
      rdata_reg   <= !s_reset && !ser_rxd && !cks_mode;
      rddly_reg   <= !s_reset && ((!ser_rxd && (rdata_reg || rddly_reg)) ||
                                  (rddly_reg && rdata_reg));
      running_reg <= !s_reset && (running_reg || rddly_reg) && (stop_reg || !shft_reg[0]) &&
                     !abort_dec;
      divider_reg <= (s_reset) ? 4'h0 : divider_nxt;
      bitclk_reg  <= !s_reset && running_reg &&
                     ((divider_reg[3] && !divider_reg[2]) ^ bitclk_reg);
      end
    end

  /*****************************************************************************************/
  /* sync state machine                                                                    */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    rx_run   <= !s_reset && (auto_trig || (!ld_bufr && rx_run));
    rx_strt  <= !s_reset && (auto_trig || (!rx_sync && rx_strt));
    sync_dly <= !s_reset && cks_mode && rx_sync;
    end

  endmodule
