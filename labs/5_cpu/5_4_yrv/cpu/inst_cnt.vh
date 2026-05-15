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
/** instantiated count increment                                      Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module inst_cnt  (cnt_out, clk, cnt_in);

  input         clk;                                       /* cpu clock                    */
  input  [31:0] cnt_in;                                    /* count to increment           */

  output [31:0] cnt_out;                                   /* count increment result       */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire   [31:0] cnt_out;                                   /* count increment result       */

`ifdef ICE40_VERSION
  /*****************************************************************************************/
  /* Lattice DSP Function                                                                  */
  /*****************************************************************************************/
  SB_MAC16      CNT   ( .CLK(clk), .CE(1'b1), .A(cnt_in[15:0]), .AHOLD(1'b0),
                        .B(16'h1), .BHOLD(1'b0), .C(cnt_in[31:16]),
                        .CHOLD(1'b0), .D(16'h0), .DHOLD(1'b0), .IRSTTOP(1'b0),
                        .ORSTTOP(1'b0), .OLOADTOP(1'b0), .ADDSUBTOP(1'b0),
                        .OHOLDTOP(1'b0), .IRSTBOT(1'b0), .ORSTBOT(1'b0), .OLOADBOT(1'b0),
                        .ADDSUBBOT(1'b0), .OHOLDBOT(1'b0), .O(cnt_out), .CI(1'b0), .CO(),
                        .ACCUMCI(1'b0), .ACCUMCO(), .SIGNEXTIN(1'b0), .SIGNEXTOUT() );

  defparam CNT.MODE_8x8              = 1'b1;
  defparam CNT.TOPADDSUB_UPPERINPUT  = 1'b1;
  defparam CNT.TOPADDSUB_CARRYSELECT = 2'b10;
  defparam CNT.BOTADDSUB_UPPERINPUT  = 1'b1;

`endif  // ICE40_VERSION

`ifdef SERIES7_VERSION
  /*****************************************************************************************/
  /* Xilinx adder                                                                          */
  /*****************************************************************************************/
  ADDSUB_MACRO       #( .DEVICE("7SERIES"), .LATENCY(0), .WIDTH(32) )
                CNT   ( .CARRYOUT(), .RESULT(inc_out), .A(inc_ain), .ADD_SUB(1'b1),
                        .B(32'h1), .CARRYIN(1'b0), .CE(1'b1), .CLK(clk),
                        .RST(1'b0) );

`endif  // SERIES7_VERSION

  endmodule
