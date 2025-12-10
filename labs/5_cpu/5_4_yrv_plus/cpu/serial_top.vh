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
/** serial i/o module                                                 Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module serial_top (bufr_done, bufr_empty, bufr_full, bufr_ovr, rx_rdata, ser_clk, ser_txd,
                   cks_mode, clkp, div_rate, ld_wdata, rd_rdata, s_reset, ser_rxd, tx_wdata);

  input         cks_mode;                                  /* sync mode                    */
  input         clkp;                                      /* main peripheral clock        */
  input         ld_wdata;                                  /* write tx data register       */
  input         rd_rdata;                                  /* read rx data register        */
  input         s_reset;                                   /* synchronous reset            */
  input         ser_rxd;                                   /* receive data input           */
  input   [7:0] tx_wdata;                                  /* write data bus               */
  input  [11:0] div_rate;                                  /* serial baud rate divider     */

  output        bufr_done;                                 /* serial tx done sending       */
  output        bufr_empty;                                /* serial tx buffer empty       */
  output        bufr_full;                                 /* serial rx buffer full        */
  output        bufr_ovr;                                  /* serial rx buffer overrun     */
  output        ser_clk;                                   /* serial clk output (cks)      */
  output        ser_txd;                                   /* transmit data output         */
  output  [7:0] rx_rdata;                                  /* receive data buffer          */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire        auto_trig;                                   /* clocked serial trigger       */
  wire        rx_run;                                      /* rcvr running (cks mode)      */
  wire        rx_sync;                                     /* internal rx clock            */
  wire        ser_txd;                                     /* transmitter data output      */
  wire        tx_run;                                      /* serial tx running (cks)      */
  wire        tx_sync;                                     /* internal tx clock            */
  wire        bufr_done;                                   /* serial tx done sending       */
  wire        bufr_empty;                                  /* serial tx buffer empty       */
  wire        bufr_full;                                   /* serial rx buffer full        */
  wire        bufr_ovr;                                    /* serial rx buffer overrun     */
  wire  [7:0] rx_rdata;                                    /* receive data buffer          */

  reg         ser_clk;                                     /* internal clock               */
  reg         ser_divpls;                                  /* divider output pulse         */
  reg  [11:0] ser_divcnt;                                  /* divider counter              */

  /*****************************************************************************************/
  /* baud rate divider                                                                     */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    ser_divcnt <= (s_reset) ? 12'h0 :
                  (~|ser_divcnt) ? div_rate : (ser_divcnt - 1'b1);
    ser_divpls <= !s_reset && ~|ser_divcnt;
    end

  /*****************************************************************************************/
  /* sync clk generator                                                                    */
  /*****************************************************************************************/
  always @ (posedge clkp) begin
    if (s_reset || ser_divpls) ser_clk <= s_reset || (!rx_run && !tx_run) || !ser_clk;
    end

  /*****************************************************************************************/
  /* clock muxes                                                                           */
  /*****************************************************************************************/
  assign rx_sync = (cks_mode) ? (ser_divpls && !ser_clk) : ser_divpls;
  assign tx_sync = (cks_mode) ? (ser_divpls &&  ser_clk) : ser_divpls;

  /*****************************************************************************************/
  /* serial port receiver and transmitter                                                  */
  /*****************************************************************************************/
  serial_rx RXCV ( .bufr_ovr(bufr_ovr), .bufr_full(bufr_full), .rx_rdata(rx_rdata),
                   .rx_run(rx_run), .auto_trig(auto_trig), .cks_mode(cks_mode), .clkp(clkp),
                   .rd_rdata(rd_rdata), .rx_sync(rx_sync), .s_reset(s_reset),
                   .ser_rxd(ser_rxd) );

  serial_tx XMIT ( .auto_trig(auto_trig), .bufr_done(bufr_done), .bufr_empty(bufr_empty),
                   .ser_txd(ser_txd), .tx_run(tx_run),.cks_mode(cks_mode), .clkp(clkp),
                   .ld_wdata(ld_wdata), .s_reset(s_reset), .tx_sync(tx_sync),
                   .tx_wdata(tx_wdata) );

  endmodule
