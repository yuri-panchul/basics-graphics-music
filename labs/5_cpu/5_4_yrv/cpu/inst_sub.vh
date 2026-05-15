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
/** instantiated subtracter                                           Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module inst_sub  (sub_cyout, sub_out, clk, sub_ain, sub_bin);

  input         clk;                                       /* cpu clock                    */
  input  [31:0] sub_ain;                                   /* primary input a              */
  input  [31:0] sub_bin;                                   /* primary input b              */

  output        sub_cyout;                                 /* subtract carry out           */
  output [31:0] sub_out;                                   /* subtract (a-b) result        */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          sub_cyout;                                 /* subtract carry out           */
  wire   [31:0] sub_out;                                   /* addition result              */

`ifdef ICE40_VERSION
  /*****************************************************************************************/
  /* Lattice DSP Function                                                                  */
  /*****************************************************************************************/
  SB_MAC16  SUBTRACT  ( .CLK(clk), .CE(1'b1), .A(sub_ain[15:0]), .AHOLD(1'b0),
                        .B(sub_bin[15:0]), .BHOLD(1'b0), .C(sub_ain[31:16]),
                        .CHOLD(1'b0), .D(sub_bin[31:16]), .DHOLD(1'b0), .IRSTTOP(1'b0),
                        .ORSTTOP(1'b0), .OLOADTOP(1'b0), .ADDSUBTOP(1'b1),
                        .OHOLDTOP(1'b0), .IRSTBOT(1'b0), .ORSTBOT(1'b0), .OLOADBOT(1'b0),
                        .ADDSUBBOT(1'b1), .OHOLDBOT(1'b0), .O(sub_out), .CI(1'b0),
                        .CO(sub_cyout), .ACCUMCI(1'b0), .ACCUMCO(), .SIGNEXTIN(1'b0),
                        .SIGNEXTOUT() );

  defparam SUBTRACT.MODE_8x8              = 1'b1;
  defparam SUBTRACT.TOPADDSUB_UPPERINPUT  = 1'b1;
  defparam SUBTRACT.TOPADDSUB_CARRYSELECT = 2'b10;
  defparam SUBTRACT.BOTADDSUB_UPPERINPUT  = 1'b1;

`endif  // ICE40_VERSION

`ifdef SERIES7_VERSION
  /*****************************************************************************************/
  /* Xilinx adder                                                                          */
  /*****************************************************************************************/
  ADDSUB_MACRO       #( .DEVICE("7SERIES"), .LATENCY(0), .WIDTH(32) )
                SUB   ( .CARRYOUT(sub_cyout), .RESULT(sub_out), .A(sub_ain), .ADD_SUB(1'b0),
                        .B(sub_bin), .CARRYIN(1'b0), .CE(1'b1), .CLK(clk),
                        .RST(1'b0) );

`endif  // SERIES7_VERSION

  endmodule
