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

  input         cks_mode;
  input         clkp;
  input         ld_wdata;
  input         rd_rdata;
  input         s_reset;
  input         ser_rxd;
  input   [7:0] tx_wdata;
  input  [11:0] div_rate;

  output        bufr_done;
  output        bufr_empty;
  output        bufr_full;
  output        bufr_ovr;
  output        ser_clk;
  output        ser_txd;
  output  [7:0] rx_rdata;

`ifdef __ICARUS__
  /*****************************************************************************************/
  /* SIMULATION MODEL: Console Output Stub                                                 */
  /*****************************************************************************************/
  reg           bufr_done;
  reg           bufr_empty;
  reg           bufr_full;
  reg           bufr_ovr;
  reg           ser_clk;
  reg           ser_txd;
  reg    [7:0]  rx_rdata;

  initial begin
    bufr_done  = 1'b1;
    bufr_empty = 1'b1;
    bufr_full  = 1'b0;
    bufr_ovr   = 1'b0;
    rx_rdata   = 8'h00;
    ser_clk    = 1'b0;
    ser_txd    = 1'b1;
  end

always @(posedge clkp) begin
    if (!s_reset && ld_wdata && (tx_wdata != 8'h00)) begin
        if (tx_wdata >= 8'h20 && tx_wdata <= 8'h7e)
            $write("%c", tx_wdata);
        else if (tx_wdata == 8'h0a || tx_wdata == 8'h0d)
            $write("%c", tx_wdata);
        else
            $write("[0x%02h]", tx_wdata);
    end
end

`else
  /*****************************************************************************************/
  /* SYNTHESIZABLE RTL: Original Implementation                                            */
  /*****************************************************************************************/
  `include "serial_rx.vh"
  `include "serial_tx.vh"

  wire          bufr_done;
  wire          bufr_empty;
  wire          bufr_full;
  wire          bufr_ovr;
  wire          ser_clk;
  wire          ser_txd;
  wire   [7:0]  rx_rdata;

  wire          auto_trig;
  wire          rx_run;
  wire          rx_sync;
  wire          tx_run;
  wire          tx_sync;

  reg           ser_clk;
  reg           ser_divpls;
  reg   [11:0]  ser_divcnt;

  always @ (posedge clkp) begin
    ser_divcnt <= (s_reset) ? 12'h0 :
                  (~|ser_divcnt) ? div_rate : (ser_divcnt - 1'b1);
    ser_divpls <= !s_reset && ~|ser_divcnt;
  end

  always @ (posedge clkp) begin
    if (s_reset || ser_divpls) ser_clk <= s_reset || (!rx_run && !tx_run) || !ser_clk;
  end

  assign rx_sync = (cks_mode) ? (ser_divpls && !ser_clk) : ser_divpls;
  assign tx_sync = (cks_mode) ? (ser_divpls &&  ser_clk) : ser_divpls;

  serial_rx RXCV ( .bufr_ovr(bufr_ovr), .bufr_full(bufr_full), .rx_rdata(rx_rdata),
                   .rx_run(rx_run), .auto_trig(auto_trig), .cks_mode(cks_mode), .clkp(clkp),
                   .rd_rdata(rd_rdata), .rx_sync(rx_sync), .s_reset(s_reset),
                   .ser_rxd(ser_rxd) );

  serial_tx XMIT ( .auto_trig(auto_trig), .bufr_done(bufr_done), .bufr_empty(bufr_empty),
                   .ser_txd(ser_txd), .tx_run(tx_run), .cks_mode(cks_mode), .clkp(clkp),
                   .ld_wdata(ld_wdata), .s_reset(s_reset), .tx_sync(tx_sync),
                   .tx_wdata(tx_wdata) );

`endif

endmodule