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
/** instantiated 32-bit system memory                                 Rev 0.0  03/31/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
module inst_mem  (mem_rdata, clk, mem_addr, mem_addr_reg, mem_ble_reg, mem_ready, mem_trans,
                  mem_wdata, mem_wr_reg);

  input         clk;                                       /* cpu clock                    */
  input         mem_ready;                                 /* memory ready                 */
  input         mem_wr_reg;                                /* latched write enable         */
  input   [1:0] mem_trans;                                 /* memory transfer type         */
  input   [3:0] mem_ble_reg;                               /* latched byte enables         */
  input  [15:0] mem_addr;                                  /* memory address               */
  input  [15:0] mem_addr_reg;                              /* latched address              */
  input  [31:0] mem_wdata;                                 /* memory write data            */

  output [31:0] mem_rdata;                                 /* memory read data             */

  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          wr_en;                                     /* mem block write enable       */
  wire   [31:0] mem_rdata;                                 /* memory read data             */

`ifdef ICE40_VERSION
  wire          rd_en0, rd_en1, rd_en2, rd_en3;            /* mem block read enables       */
  wire          wr_en0, wr_en1, wr_en2, wr_en3;            /* mem block write enables      */
  wire    [3:0] byte_mask;                                 /* memory byte masks            */
  wire   [31:0] mem0_data, mem1_data;                      /* mem block output data        */
  wire   [31:0] mem2_data, mem3_data;
  wire   [31:0] wr_mask;                                   /* memory write mask            */
`endif  // ICE40_VERSION

  /*****************************************************************************************/
  /* common logic                                                                          */
  /*****************************************************************************************/
  assign wr_en = mem_wr_reg && mem_ready;

`ifdef ICE40_VERSION
  /*****************************************************************************************/
  /* Lattice memory                                                                        */
  /*****************************************************************************************/
  assign rd_en0    = mem_trans[0] && !mem_addr_reg[11] && !mem_addr_reg[10];
  assign rd_en1    = mem_trans[0] && !mem_addr_reg[11] &&  mem_addr_reg[10];
  assign rd_en2    = mem_trans[0] &&  mem_addr_reg[11] && !mem_addr_reg[10];
  assign rd_en3    = mem_trans[0] &&  mem_addr_reg[11] &&  mem_addr_reg[10];
  assign wr_en0    = wr_en        && !mem_addr_reg[11] && !mem_addr_reg[10];
  assign wr_en1    = wr_en        && !mem_addr_reg[11] &&  mem_addr_reg[10];
  assign wr_en2    = wr_en        &&  mem_addr_reg[11] && !mem_addr_reg[10];
  assign wr_en3    = wr_en        &&  mem_addr_reg[11] &&  mem_addr_reg[10];
  assign byte_mask = ~mem_ble_reg;
  assign wr_mask   = { {8{byte_mask[3]}}, {8{byte_mask[2]}},
                       {8{byte_mask[1]}}, {8{byte_mask[0]}} }; 

  SB_RAM256x16 RAM0L  ( .RDATA(mem0_data[15:0]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en0), .RE(rd_en0), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en0), .WDATA(mem_wdata[15:0]), .WE(wr_en0),
                        .MASK(wr_mask[15:0]) );

  SB_RAM256x16 RAM0H  ( .RDATA(mem0_data[31:16]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en0), .RE(rd_en0), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en0), .WDATA(mem_wdata[31:16]), .WE(wr_en0),
                        .MASK(wr_mask[31:16]) );

  SB_RAM256x16 RAM1L  ( .RDATA(mem1_data[15:0]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en1), .RE(rd_en1), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en1), .WDATA(mem_wdata[15:0]), .WE(wr_en1),
                        .MASK(wr_mask[15:0]) );

  SB_RAM256x16 RAM1H  ( .RDATA(mem1_data[31:16]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en1), .RE(rd_en1), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en1), .WDATA(mem_wdata[31:16]), .WE(wr_en1),
                        .MASK(wr_mask[31:16]) );

  SB_RAM256x16 RAM2L  ( .RDATA(mem2_data[15:0]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en2), .RE(rd_en2), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en2), .WDATA(mem_wdata[15:0]), .WE(wr_en2),
                        .MASK(wr_mask[15:0]) );

  SB_RAM256x16 RAM2H  ( .RDATA(mem2_data[31:16]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en2), .RE(rd_en2), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en2), .WDATA(mem_wdata[31:16]), .WE(wr_en2),
                        .MASK(wr_mask[31:16]) );

  SB_RAM256x16 RAM3L  ( .RDATA(mem3_data[15:0]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en3), .RE(rd_en3), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en3), .WDATA(mem_wdata[15:0]), .WE(wr_en3),
                        .MASK(wr_mask[15:0]) );

  SB_RAM256x16 RAM3H  ( .RDATA(mem3_data[31:16]), .RADDR(mem_addr[9:2]), .RCLK(clk),
                        .RCLKE(rd_en3), .RE(rd_en3), .WADDR(mem_addr_reg[9:2]), .WCLK(clk),
                        .WCLKE(wr_en3), .WDATA(mem_wdata[31:16]), .WE(wr_en3),
                        .MASK(wr_mask[31:16]) );

  assign mem_rdata = (mem_addr_reg[11:10] == 2'b00) ? mem0_data :
                     (mem_addr_reg[11:10] == 2'b01) ? mem1_data :
                     (mem_addr_reg[11:10] == 2'b10) ? mem2_data : mem3_data;

`include "code_demo.v"

`endif  // ICE40_VERSION

`ifdef SERIES7_VERSION
  /*****************************************************************************************/
  /* Xilinx memory                                                                         */
  /*****************************************************************************************/
  BRAM_SDP_MACRO     #( .BRAM_SIZE("36Kb"), .DEVICE("7SERIES"), .WRITE_WIDTH(32),
                        .READ_WIDTH(32), .INIT_FILE("NONE"),
`include "code_demo.mif"
                        .SIM_COLLISION_CHECK("NONE"), .WRITE_MODE("READ_FIRST") )
                RAM_1 ( .DO(mem_rdata), .DI(mem_wdata), .RDADDR(mem_addr[11:2]), .RDCLK(clk),
                        .RDEN(mem_trans[0]), .REGCE(1'b1), .RST(1'b0), .WE(mem_ble_reg),
                        .WRADDR(mem_addr_reg[11:2]), .WRCLK(clk), .WREN(wr_en) );

`endif  // SERIES7_VERSION

`ifdef INTEL_VERSION
  /*****************************************************************************************/
  /* Intel FPGA / former Altera memory                                                     */
  /*****************************************************************************************/

  /*****************************************************************************************/
  /* This option allows to create examples with read-only memory                           */
  /* when booting from UART is not available.                                              */
  /*                                                                                       */
  /* Another option, readmemh in yrv_mcu.v under ifndef INSTANCE_MEM, is not going to work */
  /* because Intel FPGA Quartus Prime does not support 8-bit readmemh for synthesis.       */
  /*****************************************************************************************/
 
  reg [31:0] rom[0:255];

  initial $readmemh("code_demo.mem32", rom);

  assign mem_rdata = rom[mem_addr_reg[9:2]];

`endif  // INTEL_VERSION

  endmodule
