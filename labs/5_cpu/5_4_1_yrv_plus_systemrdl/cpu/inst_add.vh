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
/** instantiated adder                                                Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module inst_add  (add_out, clk, add_ain, add_bin, add_cyin);

  input         clk;                                       /* cpu clock                    */
  input         add_cyin;                                  /* carry input                  */
  input  [31:0] add_ain;                                   /* primary input a              */
  input  [31:0] add_bin;                                   /* primary input b              */

  output [31:0] add_out;                                   /* addition result              */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire   [31:0] add_out;                                   /* addition result              */

`ifdef ICE40_VERSION
  /*****************************************************************************************/
  /* Lattice DSP Function                                                                  */
  /*****************************************************************************************/
  SB_MAC16     ADDER  ( .CLK(clk), .CE(1'b1), .A(add_ain[15:0]), .AHOLD(1'b0),
                        .B(add_bin[15:0]), .BHOLD(1'b0), .C(add_ain[31:16]),
                        .CHOLD(1'b0), .D(add_bin[31:16]), .DHOLD(1'b0), .IRSTTOP(1'b0),
                        .ORSTTOP(1'b0), .OLOADTOP(1'b0), .ADDSUBTOP(1'b0),
                        .OHOLDTOP(1'b0), .IRSTBOT(1'b0), .ORSTBOT(1'b0), .OLOADBOT(1'b0),
                        .ADDSUBBOT(1'b0), .OHOLDBOT(1'b0), .O(add_out), .CI(add_cyin), .CO(),
                        .ACCUMCI(1'b0), .ACCUMCO(), .SIGNEXTIN(1'b0), .SIGNEXTOUT() );

  defparam ADDER.MODE_8x8              = 1'b1;
  defparam ADDER.TOPADDSUB_UPPERINPUT  = 1'b1;
  defparam ADDER.TOPADDSUB_CARRYSELECT = 2'b10;
  defparam ADDER.BOTADDSUB_UPPERINPUT  = 1'b1;

`endif  // ICE40_VERSION

`ifdef SERIES7_VERSION
  /*****************************************************************************************/
  /* Xilinx adder                                                                          */
  /*****************************************************************************************/
  ADDSUB_MACRO       #( .DEVICE("7SERIES"), .LATENCY(0), .WIDTH(32) )
                ADDER ( .CARRYOUT(), .RESULT(add_out), .A(add_ain), .ADD_SUB(1'b1),
                        .B(add_bin), .CARRYIN(add_cyin), .CE(1'b1), .CLK(clk),
                        .RST(1'b0) );

`endif  // SERIES7_VERSION

  endmodule
