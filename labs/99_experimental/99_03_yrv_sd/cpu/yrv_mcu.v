/*******************************************************************************************/
/**                                                                                       **/
/** Copyright 2021 Monte J. Dalrymple                                                     **/
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
/** YRV simple mcu system                                             Rev 0.0  03/29/2021 **/
/**                                                                                       **/
/*******************************************************************************************/
`define IO_BASE   16'hffff                                 /* msword of i/o address        */
`define IO_PORT10 14'h0000                                 /* lsword of port 1/0 address   */
`define IO_PORT32 14'h0001                                 /* lsword of port 3/2 address   */
`define IO_PORT54 14'h0002                                 /* lsword of port 5/4 address   */
`define IO_PORT76 14'h0003                                 /* lsword of port 7/6 address   */
`define MEM_BASE  16'h0000                                 /* msword of mem address        */


/* processor                                                                               */
`include "yrv_top.vh"



// For real boards
`ifndef SIMULATION
`define BOOT_FROM_AUX_UART
`define USE_MEM_BANKS_FOR_BYTE_LINES
`define NO_READMEMH_FOR_8_BIT_WIDE_MEM
`define EXPOSE_MEM_BUS
`endif 


`include "sd/sd_controller.vh"
`include "boot_uart_receiver.svh"

module yrv_mcu
# (
  parameter clk_frequency = 50 * 1000 * 1000
)
(                debug_mode, port0_reg, port1_reg, port2_reg, port3_reg, ser_clk, ser_txd,
                 wfi_state, clk, ei_req, nmi_req, port4_in, port5_in, resetb, ser_rxd

                 `ifdef BOOT_FROM_AUX_UART
                 , aux_uart_rx
                 `endif
                 `ifdef EXPOSE_MEM_BUS
                 , mem_ready, mem_rdata, mem_lock, mem_write, mem_trans, mem_ble,
                 mem_addr, mem_wdata, extra_debug_data,
                 sd_cs,sd_mosi,sd_miso,sd_sclk,sd_status,byte_cnt_res,current_addr_sector_res,sd_ready
                 ,byte_available_res

                 `endif
               
  );

  input         clk;                                       /* cpu clock                    */
  input         ei_req;                                    /* external int request         */
  input         nmi_req;                                   /* non-maskable interrupt       */
  input         resetb;                                    /* master reset                 */
  input         ser_rxd;                                   /* receive data input           */
  input  [15:0] port4_in;                                  /* port 4                       */
  input  [15:0] port5_in;                                  /* port 5                       */

  output        debug_mode;                                /* in debug mode                */
  output        ser_clk;                                   /* serial clk output (cks mode) */
  output        ser_txd;                                   /* transmit data output         */
  output        wfi_state;                                 /* waiting for interrupt        */
  output [15:0] port0_reg;                                 /* port 0                       */
  output [15:0] port1_reg;                                 /* port 1                       */
  output [15:0] port2_reg;                                 /* port 2                       */
  output [15:0] port3_reg;                                 /* port 3                       */

`ifdef BOOT_FROM_AUX_UART
  input         aux_uart_rx;                               /* auxiliary UART receive pin   */
`endif

`ifdef EXPOSE_MEM_BUS
  output        mem_ready;                                 /* memory ready                 */
  output [31:0] mem_rdata;                                 /* memory read data             */
  output        mem_lock;                                  /* memory lock (rmw)            */
  output        mem_write;                                 /* memory write enable          */
  output  [1:0] mem_trans;                                 /* memory transfer type         */
  output  [3:0] mem_ble;                                   /* memory byte lane enables     */
  output [31:0] mem_addr;                                  /* memory address               */
  output [31:0] mem_wdata;                                 /* memory write data            */

  output [31:0] extra_debug_data;                          /* extra debug data unconnected */

  output sd_cs;
  output sd_mosi;
  input  sd_miso;
  output sd_sclk;
  output [5:0] sd_status;
  output [9:0] byte_cnt_res;
  output [22:0] current_addr_sector_res;
  output byte_available_res;
  output sd_ready;
`endif

assign byte_cnt_res = byte_cnt;
assign current_addr_sector_res = adr ;
assign byte_available_res = byte_available;
  /*****************************************************************************************/
  /* signal declarations                                                                   */
  /*****************************************************************************************/
  wire          bufr_done;                                 /* serial tx done sending       */
  wire          bufr_empty;                                /* serial tx buffer empty       */
  wire          bufr_full;                                 /* serial rx buffer full        */
  wire          bufr_ovr;                                  /* serial rx buffer overrun     */
  wire          bus_32;                                    /* 32-bit bus select            */
  wire          debug_mode;                                /* in debug mode                */
  wire          ld_wdata;                                  /* serial port write            */
  wire          mem_ready;                                 /* memory ready                 */
  wire          mem_write;                                 /* memory write enable          */
  wire          port10_dec, port32_dec;                    /* i/o port decodes             */
  wire          port54_dec, port76_dec;
  wire          rd_rdata;                                  /* serial port read             */
  wire          ser_clk;                                   /* serial clk output (cks mode) */
  wire          ser_txd;                                   /* transmit data output         */
  wire          wfi_state;                                 /* waiting for interrupt        */
  wire    [1:0] mem_trans;                                 /* memory transfer type         */
  wire    [3:0] mem_ble;                                   /* memory byte lane enables     */
  wire    [7:0] rx_rdata;                                  /* receive data buffer          */
  wire         uart_byte_valid;
  wire   [15:0] li_req;                                    /* local int requests           */
  wire   [15:0] port7_dat;                                 /* i/o port                     */
  wire   [31:0] mcu_rdata;                                 /* system memory read data      */
  wire   [31:0] mem_addr;                                  /* memory address               */
  wire   [31:0] mem_wdata;                                 /* memory write data            */

  reg           io_rd_reg;                                 /* i/o read                     */
  reg           io_wr_reg;                                 /* i/o write                    */
  reg           mem_rd_reg;                                /* mem read                     */
  reg           mem_wr_reg;                                /* mem write                    */
  reg     [3:0] mem_ble_reg;                               /* reg'd memory byte lane en    */
  reg    [15:0] port0_reg,  port1_reg;                     /* i/o ports                    */
  reg    [15:0] port2_reg,  port3_reg;
  reg    [15:0] port4_reg,  port5_reg;
  reg    [15:0] port6_reg,  port7_reg;
  reg    [15:0] mem_addr_reg;                                   /* reg'd memory address         */


  /*****************************************************************************************/
  /* This option allows to create examples with read-only memory                           */
  /* when booting from UART is not available.                                              */
  /*                                                                                       */
  /* Note that Intel FPGA Quartus Prime does not support 8-bit readmemh for synthesis.     */
  /* It means that the user has to either use booting from UART                            */
  /* or rely on read-only 32-bit wide memory inside inst_mem.v undef ifdef INSTANCE_MEM.   */
  /*****************************************************************************************/


  wire    [3:0] mem_wr_byte;                               /* system ram byte enables      */

  reg     [7:0] mcu_mem_bank0 [0:127];                    /* system ram banks             */
  reg     [7:0] mcu_mem_bank1 [0:127];
  reg     [7:0] mcu_mem_bank2 [0:127];
  reg     [7:0] mcu_mem_bank3 [0:127];
  reg    [31:0] mem_rdata;                                 /* raw read data                */



  /*****************************************************************************************/
  /* 32-bit bus, no wait states, internal local interrupts                                 */
  /*****************************************************************************************/
  assign bus_32    = 1'b1;
  reg mem_ready_reg;
  assign mem_ready = mem_ready_reg;
  assign li_req    = {12'h0, bufr_empty, bufr_done, bufr_full, bufr_ovr};

  /*****************************************************************************************/
  /* processor                                                                             */
  /*****************************************************************************************/



  yrv_top YRV     ( .csr_achk(), .csr_addr(), .csr_read(), .csr_wdata(), .csr_write(),
                    .debug_mode(debug_mode), .ebrk_inst(), .mem_addr(mem_addr),
                    .mem_ble(mem_ble), .mem_lock(), .mem_trans(mem_trans),
                    .mem_wdata(mem_wdata), .mem_write(mem_write), .timer_en(),
                    .wfi_state(wfi_state), .brk_req(1'b0), .bus_32(bus_32), .clk(clk),
                    .csr_ok_ext(1'b0), .csr_rdata(32'h0), .dbg_req(1'b0),
                    .dresetb(resetb), .ei_req(ei_req), .halt_reg(1'b0), .hw_id(10'h0),
                    .li_req(li_req), .mem_rdata(mem_rdata), .mem_ready(mem_ready),
                    .nmi_req(nmi_req), .resetb(resetb), .sw_req(1'b0),
                    .timer_match(1'b0), .timer_rdata(64'h0) );


  /*****************************************************************************************/
  /* 32-bit memory (currently 1k x 32)                                                     */
  /*****************************************************************************************/

parameter STATE_INIT = 0;
parameter STATE_START = 1;
parameter STATE_WRITE = 2;
parameter STATE_READ = 3;
parameter STATE_IDLE = 4;
parameter STATE_WAIT_RELEASE = 5;
wire [4:0] state;


wire trans_start = mem_trans && mem_ready; 
wire mem_read_addr;
assign mem_read_addr = !mem_write &&  mem_trans[0] && (mem_addr[31:16] == `MEM_BASE);

assign sd_status = state;

wire [22:0] current_addr_sector = mem_addr[31:9]; 
reg  [22:0] cached_sector_tag; 
reg  [9:0] byte_cnt;
reg  [7:0] dout;

    reg rd = 0;
    reg wr = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire byte_available;
    wire ready;
    wire ready_for_next_byte;
    reg [31:0] adr;
    reg [2:0] test_state; 


// Условие хита
wire hit = (current_addr_sector == cached_sector_tag);
wire byte_available;
wire card_ready;
wire reset = ~ resetb;
reg [2:0]clkcounter = 0;

    always @ (posedge clk) begin
        if (reset) clkcounter <= 3'b0;
        else clkcounter <= clkcounter + 1;
    end

wire clk_pulse_slow = (clkcounter == 3'b0);
assign sd_ready = ready;
sd_controller sdcont(.cs(sd_cs), .mosi(sd_mosi), .miso(sd_miso),
            .sclk(sd_sclk), .rd(rd), .wr(wr), .reset(reset),
            .din(din), .dout(dout), .byte_available(byte_available),
            .ready(ready), .address(adr), 
            .ready_for_next_byte(ready_for_next_byte), .clk(clk), 
            .status(state), .clk_pulse_slow(clk_pulse_slow));


      always @(posedge clk) begin
                if(reset) begin
                    byte_cnt<= 0;
                    din <= 0;
                    wr <= 0;
                    rd <= 0;
                    adr <=0;
                    test_state <= STATE_INIT; 
                    adr <= 32'h00_00_02_00;
                    cached_sector_tag <=0;
                    mem_ready_reg <= 1'b0;
                end
                else begin
                     case (test_state)
                           STATE_INIT: begin
                                if(ready) begin
                                    test_state <= STATE_START;
                                    mem_ready_reg <= 1'b0;
                                    byte_cnt<= 0;
                                    rd <= 1;       
                                end
                            end

                            STATE_START: begin
                                    if(ready == 0) begin
                                        test_state <= STATE_READ;
                                        rd <= 0;       
                                    end
                            end

                            STATE_READ: begin
                                if(byte_available && clk_pulse_slow) begin
                                    case (byte_cnt[1:0])
                                        2'b00: mcu_mem_bank0[byte_cnt[8:2]] <= dout;
                                        2'b01: mcu_mem_bank1[byte_cnt[8:2]] <= dout;
                                        2'b10: mcu_mem_bank2[byte_cnt[8:2]] <= dout;
                                        2'b11: mcu_mem_bank3[byte_cnt[8:2]] <= dout;
                                    endcase
                                    if (byte_cnt == 511) begin
                                        test_state <= STATE_IDLE;
                                        cached_sector_tag <= current_addr_sector; 
                                    end else begin
                                        byte_cnt <= byte_cnt + 1'b1;
                                    end
                                end
                            end

                            STATE_IDLE: begin
                            if (mem_read_addr) begin
                               if (hit) begin
                                  mem_rdata[31:24] <= mcu_mem_bank3[mem_addr[8:2]];
                                  mem_rdata[23:16] <= mcu_mem_bank2[mem_addr[8:2]];
                                  mem_rdata[15:8]  <= mcu_mem_bank1[mem_addr[8:2]];
                                  mem_rdata[7:0]   <= mcu_mem_bank0[mem_addr[8:2]];
                                  mem_ready_reg    <= 1'b1;
                                end else begin
                                    mem_ready_reg <= 1'b0;
                                    adr <= mem_addr;
                                    test_state <= STATE_INIT;
                                end
                              end else begin
                                mem_ready_reg <= 1'b0;
                              end    
                            end
                    endcase
                end
            end
    





  /*****************************************************************************************/
  /* bus interface                                                                         */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      mem_addr_reg <= 16'h0;
      mem_ble_reg  <=  4'h0;
      io_rd_reg    <=  1'b0;
      io_wr_reg    <=  1'b0;
      mem_rd_reg   <=  1'b0;
      mem_wr_reg   <=  1'b0;
      end
    else if (mem_ready) begin
      mem_addr_reg  <= mem_addr[15:0];
      mem_ble_reg   <= mem_ble;
      io_rd_reg     <= !mem_write &&  mem_trans[0] && (mem_addr[31:16] == `IO_BASE);
      io_wr_reg     <=  mem_write && &mem_trans    && (mem_addr[31:16] == `IO_BASE);
      mem_rd_reg    <= !mem_write &&  mem_trans[0] && (mem_addr[31:16] == `MEM_BASE);
      mem_wr_reg    <=  mem_write && &mem_trans    && (mem_addr[31:16] == `MEM_BASE);
      end
    end



  assign port10_dec = (mem_addr_reg[15:2] == `IO_PORT10);
  assign port32_dec = (mem_addr_reg[15:2] == `IO_PORT32);
  assign port54_dec = (mem_addr_reg[15:2] == `IO_PORT54);
  assign port76_dec = (mem_addr_reg[15:2] == `IO_PORT76);

  assign mcu_rdata  = (mem_rd_reg) ? mem_rdata              :
                      (port10_dec) ? {port1_reg, port0_reg} :
                      (port32_dec) ? {port3_reg, port2_reg} :
                      (port54_dec) ? {port5_reg, port4_reg} :
                      (port76_dec) ? {port7_reg, port6_reg} : 32'h0;

  /*****************************************************************************************/
  /* parallel ports                                                                        */
  /*****************************************************************************************/
  always @ (posedge clk or negedge resetb) begin
    if (!resetb) begin
      port0_reg <= 16'h0;
      port1_reg <= 16'h0;
      port2_reg <= 16'h0;
      port3_reg <= 16'h0;
      port4_reg <= 16'h0;
      port5_reg <= 16'h0;
      port6_reg <= 16'h0;
      end
    else begin
      if (io_wr_reg && port10_dec && mem_ready) begin
        if (mem_ble_reg[3]) port1_reg[15:8] <= mem_wdata[31:24];
        if (mem_ble_reg[2]) port1_reg[7:0]  <= mem_wdata[23:16];
        if (mem_ble_reg[1]) port0_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port0_reg[7:0]  <= mem_wdata[7:0];
        end
      if (io_wr_reg && port32_dec && mem_ready) begin
        if (mem_ble_reg[3]) port3_reg[15:8] <= mem_wdata[31:24];
        if (mem_ble_reg[2]) port3_reg[7:0]  <= mem_wdata[23:16];
        if (mem_ble_reg[1]) port2_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port2_reg[7:0]  <= mem_wdata[7:0];
        end
      port4_reg <= port4_in;
      port5_reg <= port5_in;
      if (io_wr_reg && port76_dec && mem_ready) begin
        if (mem_ble_reg[1]) port6_reg[15:8] <= mem_wdata[15:8];
        if (mem_ble_reg[0]) port6_reg[7:0]  <= mem_wdata[7:0];
        end
      end
    end

  /*****************************************************************************************/
  /* serial port                                                                           */
  /*****************************************************************************************/

  boot_uart_receiver
  # (
    .clk_frequency ( clk_frequency )
  )
  UART_RECEIVER
  (
    .clk        ( clk                 ),
    .reset      ( ~ resetb            ),
    .rx         ( ser_rxd             ),
    .byte_valid ( uart_byte_valid     ),
    .byte_data  ( rx_rdata            )
  );

  assign port7_dat =  {7'h0, uart_byte_valid, rx_rdata};
  
  always @ (posedge clk or negedge resetb) begin
     if (!resetb) 
        port7_reg <='0;
     else
        if(uart_byte_valid && (~port7_reg[8]) )
          port7_reg <= port7_dat;
        else if (port76_dec)
          port7_reg[8] = 1'b0;

  end
  
  endmodule
