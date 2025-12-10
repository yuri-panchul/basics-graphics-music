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
/** serial transmitter module (async/sync)                            Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module serial_tx (auto_trig, bufr_done, bufr_empty, ser_txd, tx_run, cks_mode, clkp,
                  ld_wdata, s_reset, tx_sync, tx_wdata);

  input         cks_mode;                                  /* clocked serial mode          */
  input         clkp;                                      /* main peripheral clock        */
  input         ld_wdata;                                  /* write tx data register       */
  input         s_reset;                                   /* synchronous reset            */
  input         tx_sync;                                   /* transmit clock enable        */
  input   [7:0] tx_wdata;                                  /* write data bus               */

  output        auto_trig;                                 /* clocked serial trigger       */
  output        bufr_done;                                 /* tranmsit idle                */
  output        bufr_empty;                                /* transmit buffer empty        */
  output        ser_txd;                                   /* transmit data output         */
  output        tx_run;                                    /* transmit is running          */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire        auto_trig;                                   /* clocked serial trigger       */
  wire        bitclk_pls;                                  /* tx bit clock                 */
  wire        bufr_done;                                   /* async byte finished          */
  wire        bufr_empty;                                  /* buffer empty output          */
  wire        divide_pls;                                  /* bit cell boundary/middle     */
  wire        lastbit;                                     /* shifter empty                */
  wire        ld_bufr;                                     /* load sr with data            */
  wire        ld_shft;                                     /* shifter load control         */
  wire        ser_txd;                                     /* transmit data output         */
  wire        termchar;                                    /* terminate char tx            */
  wire        tx_run;                                      /* cks running                  */
  wire  [7:0] bufr_rev;                                    /* msb-first data               */

  reg         bitclk_reg;                                  /* bit clock                    */
  reg         bufr_full;                                   /* buffer full flag             */
  reg         ending_reg;                                  /* stop bit sending             */
  reg         output_reg;                                  /* output register              */
  reg         running_reg;                                 /* sending byte                 */
  reg         strt_reg;                                    /* tx start cmd latched         */
  reg   [3:0] divider_nxt, divider_reg;                    /* clock divider                */
  reg   [7:0] bufr_reg;                                    /* data buffer byte             */
  reg   [9:0] shft_nxt, shft_reg;                          /* tx shifter                   */

  /*****************************************************************************************/
  /* serial transmitter control signals                                                    */
  /*****************************************************************************************/
  assign auto_trig   = cks_mode && ld_wdata;
  assign bitclk_pls  = tx_sync && ((divide_pls && !bitclk_reg) || cks_mode);
  assign bufr_done   = !bufr_full && !running_reg;
  assign bufr_empty  = !bufr_full;
  assign bufr_rev    = {bufr_reg[0], bufr_reg[1], bufr_reg[2], bufr_reg[3],
                        bufr_reg[4], bufr_reg[5], bufr_reg[6], bufr_reg[7]};
  assign divide_pls  = divider_reg[3] && !divider_reg[2];
  assign lastbit     = ~|shft_reg[9:3] && ((cks_mode && shft_reg[2]) ||
                                          (!cks_mode && ~|shft_reg[2:1] && shft_reg[0]));
  assign ld_bufr     = bufr_full &&
                       ((tx_sync && !running_reg && (!cks_mode || strt_reg)) ||
                       (!cks_mode && ending_reg && bitclk_pls));
  assign ld_shft     = bitclk_pls && running_reg;
  assign ser_txd     = (cks_mode) ? !shft_reg[0] : !output_reg;
  assign termchar    = (cks_mode) ? lastbit : (ending_reg && bitclk_pls);
  assign tx_run      = cks_mode && (strt_reg || running_reg || (ending_reg && !tx_sync));

  always @ (cks_mode or ld_bufr or bufr_reg or bufr_rev or shft_reg) begin
    case ({cks_mode, ld_bufr})
      2'b01:   shft_nxt = {1'b1, 1'b0,        !bufr_reg[7], ~bufr_reg[6:0]};
      2'b11:   shft_nxt = {1'b0, 1'b1,        !bufr_rev[7], ~bufr_rev[6:0]};
      default: shft_nxt = {1'b0, shft_reg[9], shft_reg[8],   shft_reg[7:1]};
      endcase
    end

  /*****************************************************************************************/
  /* serial transmitter buffer and status                                                  */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    bufr_full <= !s_reset && (ld_wdata  || (!ld_bufr && bufr_full));
    end

  always @ (posedge clkp) begin
    if (ld_wdata) bufr_reg <= tx_wdata;
    end

  /*****************************************************************************************/
  /* serial transmitter shifter                                                            */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    if (ld_bufr || ld_shft || s_reset) begin
      output_reg <= !s_reset && (ld_bufr || (lastbit ^ shft_reg[0]));
      shft_reg   <= (s_reset) ? 10'h000 : shft_nxt;
      end
    end

  /*****************************************************************************************/
  /* serial transmitter state machine                                                      */
  /*****************************************************************************************/
  always @ (divider_reg or running_reg) begin
    casex ({running_reg, divider_reg})
      5'b0xxxx,
      5'b110xx: divider_nxt = 4'b0000;
      5'b10000: divider_nxt = 4'b0001;
      default:  divider_nxt = {divider_reg[2:0], !divider_reg[3]};
      endcase
    end

  always @ (posedge clkp) begin
    if (tx_sync || s_reset) begin
      running_reg <= !s_reset && (ld_bufr ||
                                 (running_reg && ((!cks_mode && bufr_full) || !termchar)));
      divider_reg <= (s_reset) ? 4'h0 : divider_nxt;
      bitclk_reg  <= !s_reset && (ld_bufr || (running_reg && (divide_pls ^ bitclk_reg)));
      end
    end

  always @ (posedge clkp) begin
    if (bitclk_pls || s_reset) ending_reg <= !s_reset && lastbit;
    end

  always @ (posedge clkp) begin
    strt_reg <= !s_reset && (auto_trig || (!ld_bufr && strt_reg));
    end

  endmodule
