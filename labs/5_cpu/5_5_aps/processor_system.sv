module processor_system(

  input  logic        clk10mhz_i,
  input  logic        clk25175khz_i,
  input  logic        rst_i,

  // Входы и выходы периферии
  input  logic [15:0] sw_i,       // Переключатели

  output logic [15:0] led_o,      // Светодиоды

  input  logic        kclk_i,     // Тактирующий сигнал клавиатуры
  input  logic        kdata_i,    // Сигнал данных клавиатуры

  output logic [ 6:0] hex_led_o,  // Вывод семисегментных индикаторов
  output logic [ 7:0] hex_sel_o,  // Селектор семисегментных индикаторов

  input  logic        rx_i,       // Линия приема по UART
  output logic        tx_o,       // Линия передачи по UART

  output logic [3:0]  vga_r_o,    // Красный канал vga
  output logic [3:0]  vga_g_o,    // Зеленый канал vga
  output logic [3:0]  vga_b_o,    // Синий канал vga
`ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
  input  logic [11:0] vga_x_i,
  input  logic [11:0] vga_y_i,
`else
  output logic        vga_hs_o,   // Линия горизонтальной синхронизации vga
  output logic        vga_vs_o,   // Линия вертикальной синхронизации vga
`endif
  input  logic        tck_i,
  input  logic        tms_i,
  input  logic        tdi_i,
  output logic        tdo_o,
  output logic        tdo_en_o

);
import platform_pkg::*;
logic sysclk, rst, vga_clk;

assign vga_clk  = clk25175khz_i;
assign rst      = rst_i;
assign sysclk   = clk10mhz_i;

/*
  =====================================================
  IRQ signals
  =====================================================
*/
logic [15:0] irq_req;
logic [15:0] irq_ret;
/*
- irq_req[1] — переключатели
- irq_req[3] — клавиатура PS/2
- irq_req[5] — UART RX
- irq_req[8] — таймер
- Остальные линии прерываний зарезервированы
*/
assign irq_req[15:9] = 7'b0;
assign irq_req[7:6]  = 2'b0;
assign irq_req[4]    = 1'b0;
assign irq_req[2]  = 3'b0;
assign irq_req[0]  = 3'b0;
//=====================================================



/*
  =====================================================
  Instr mem ports signals
  =====================================================
*/
  logic [31:0] instr_addr;
  logic [31:0] instr;
//=====================================================



/*
  =====================================================
  LSU ports signals
  =====================================================
*/
  logic         core_stall;
  logic         core_req;
  logic         core_we;
  logic [ 2:0]  core_size;
  logic [31:0]  core_wd;
  logic [31:0]  core_addr;
  logic [31:0]  core_rd;
  logic         lsu_mem_ready;
  logic         lsu_mem_req;
  logic         lsu_mem_we;
  logic [ 3:0]  lsu_mem_be;
  logic [31:0]  lsu_mem_wd;
  logic [31:0]  lsu_mem_addr;
  logic [31:0]  lsu_mem_rd;
//=====================================================



/*
  =====================================================
  Bluster ports signals
  =====================================================
*/
logic [31:0]  bl_instr_addr_o;
logic [31:0]  bl_instr_wdata_o;
logic         bl_instr_we_o;

logic [31:0]  bl_data_addr_o;
logic [31:0]  bl_data_wdata_o;
logic         bl_data_we_o;

logic         bl_tx;

logic         bl2core_rst;
//=====================================================



/*
  =====================================================
  JTAG ports signals
  =====================================================
*/
logic         trst;
logic         halt;
logic         step;
logic         jtag2core_rst;
logic         jtag2bluster_rst;


// Пересинхронизация rst_i -> trst_i
logic trst_ff1, trst_ff2;

always_ff @(posedge tck_i or posedge rst) begin
    if (rst) begin
        trst_ff1 <= 1'b1;
    end
    else begin
        trst_ff1 <= 1'b0;
    end
end

always_ff @(posedge tck_i or posedge rst) begin
    if (rst) begin
        trst_ff2 <= 1'b1;
    end
    else begin
        trst_ff2 <= trst_ff1;
    end
end

assign trst = trst_ff2;
//=====================================================



/*
  =====================================================
  Memory signals
  =====================================================
*/
logic [31:0]  mem_addr;
logic [ 7:0]  mem_high_addr;
logic [23:0]  mem_low_addr;
logic [31:0]  mem_wd;
logic         mem_we;
logic [ 3:0]  mem_be;
logic         mem_req;

logic [255:0] req;
logic [31:0]  rdata[9];
logic         ready[9];

assign mem_high_addr  = bl2core_rst ?
                              bl_data_addr_o[31:24] : lsu_mem_addr[31:24];
assign mem_low_addr   = bl2core_rst ?
                              bl_data_addr_o[23:0]  : lsu_mem_addr[23:0];
assign mem_addr       = {8'd0, mem_low_addr};
assign mem_we         = bl2core_rst ?  bl_data_we_o : lsu_mem_we;
assign mem_be         = bl2core_rst ?          4'hf : lsu_mem_be;
assign mem_req        = bl2core_rst ?  bl_data_we_o : lsu_mem_req;
assign mem_wd         = bl2core_rst ?  bl_data_wdata_o : lsu_mem_wd;

assign req = (255'd1 << mem_high_addr) & {256{mem_req}};

always_comb begin
  case(mem_high_addr)
       8'd0: lsu_mem_rd = rdata[0];
       8'd1: lsu_mem_rd = rdata[1];
       8'd2: lsu_mem_rd = rdata[2];
       8'd3: lsu_mem_rd = rdata[3];
       8'd4: lsu_mem_rd = rdata[4];
       8'd5: lsu_mem_rd = rdata[5];
       8'd6: lsu_mem_rd = rdata[6];
       8'd7: lsu_mem_rd = rdata[7];
       8'd8: lsu_mem_rd = rdata[8];
    default: lsu_mem_rd = '0;
  endcase
end

always_comb begin
  case(mem_high_addr)
       8'd0: lsu_mem_ready = ready[0];
       8'd1: lsu_mem_ready = ready[1];
       8'd2: lsu_mem_ready = ready[2];
       8'd3: lsu_mem_ready = ready[3];
       8'd4: lsu_mem_ready = ready[4];
       8'd5: lsu_mem_ready = ready[5];
       8'd6: lsu_mem_ready = ready[6];
       8'd7: lsu_mem_ready = ready[7];
       8'd8: lsu_mem_ready = ready[8];
    default: lsu_mem_ready = '0;
  endcase
end
//=====================================================



/*
  =====================================================
  CPU signals
  =====================================================
*/
  logic pc_disable, core_rst;
  assign core_rst   = bl2core_rst | jtag2core_rst;
  assign pc_disable = core_stall | (halt & ~step);
//=====================================================



/*
  =====================================================
  UART TX signals
  =====================================================
*/
  logic uart_tx;
  assign tx_o = bl2core_rst ? bl_tx : uart_tx;
//=====================================================



/*
  =====================================================
  Modules instantiation
  =====================================================
*/
    rw_instr_mem imem_inst(
      .clk_i                (sysclk                 ),
      .write_addr_i         (bl_instr_addr_o        ),
      .write_data_i         (bl_instr_wdata_o       ),
      .write_enable_i       (bl_instr_we_o          ),
      .read_addr_i          (instr_addr             ),
      .read_data_o          (instr                  )
    );

    lsu lsu_inst (
      .clk_i                (sysclk                 ),
      .rst_i                (rst                    ),
      .core_req_i           (core_req               ),
      .core_we_i            (core_we                ),
      .core_size_i          (core_size              ),
      .core_addr_i          (core_addr              ),
      .core_wd_i            (core_wd                ),
      .core_rd_o            (core_rd                ),
      .core_stall_o         (core_stall             ),
      .mem_req_o            (lsu_mem_req            ),
      .mem_we_o             (lsu_mem_we             ),
      .mem_be_o             (lsu_mem_be             ),
      .mem_addr_o           (lsu_mem_addr           ),
      .mem_wd_o             (lsu_mem_wd             ),
      .mem_rd_i             (lsu_mem_rd             ),
      .mem_ready_i          (lsu_mem_ready          )
    );

    processor_core core_inst(
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .stall_i              (pc_disable             ),
      .instr_i              (instr                  ),
      .mem_rd_i             (core_rd                ),
      .irq_req_i            (irq_req                ),
      .instr_addr_o         (instr_addr             ),
      .mem_req_o            (core_req               ),
      .mem_we_o             (core_we                ),
      .mem_size_o           (core_size              ),
      .mem_wd_o             (core_wd                ),
      .mem_addr_o           (core_addr              ),
      .irq_ret_o            (irq_ret                )
    );

    data_mem dmem_inst(
      .clk_i                (sysclk                 ),
      .mem_req_i            (req[0]                 ),
      .write_enable_i       (mem_we                 ),
      .byte_enable_i        (mem_be                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[0]               ),
      .ready_o              (ready[0]               )
    );

  if(PLATFORM_SUPPORT_SWITCHES) begin
    sw_sb_ctrl sw_sb_ctrl(
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[1]                 ),
      .write_enable_i       (mem_we                 ),
      .addr_i               (mem_addr               ),
      .write_data_i         (mem_wd                 ),
      .read_data_o          (rdata[1]               ),
      .ready_o              (ready[1]               ),
      .interrupt_return_i   (irq_ret[1]             ),
      .interrupt_request_o  (irq_req[1]             ),
      .sw_i                 (sw_i                   )
    );
  end
  else begin
    assign   rdata[1] = '0;
    assign   ready[1] = '0;
    assign irq_req[1] = '0;
  end

  if(PLATFORM_SUPPORT_LEDS) begin
    led_sb_ctrl led_sb_ctrl(
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[2]                 ),
      .write_enable_i       (mem_we                 ),
      .addr_i               (mem_addr               ),
      .write_data_i         (mem_wd                 ),
      .read_data_o          (rdata[2]               ),
      .ready_o              (ready[2]               ),
      .led_o                (led_o                  )
    );
  end
  else begin
    assign rdata[2] = '0;
    assign ready[2] = '0;
    assign led_o    = 'z;
  end

  if(PLATFORM_SUPPORT_PS2) begin
    ps2_sb_ctrl ps2_inst(
      .*,
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[3]                 ),
      .write_enable_i       (mem_we                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[3]               ),
      .ready_o              (ready[3]               ),
      .interrupt_request_o  (irq_req[3]             ),
      .interrupt_return_i   (irq_ret[3]             )
    );
  end
  else begin
    assign   rdata[3] = '0;
    assign   ready[3] = '0;
    assign irq_req[3] = '0;
  end

  if(PLATFORM_SUPPORT_7SEG) begin
    hex_sb_ctrl hex_inst(
      .*,
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[4]                 ),
      .write_enable_i       (mem_we                 ),
      .byte_enable_i        (mem_be                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[4]               ),
      .ready_o              (ready[4]               )
    );
  end
  else begin
    assign    rdata[4] = '0;
    assign    ready[4] = '0;
    assign   hex_led_o = 'z;
    assign   hex_sel_o = 'z;
  end

  if(PLATFORM_SUPPORT_UART_RX) begin
    uart_rx_sb_ctrl   rx_inst(
      .*,
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[5]                 ),
      .write_enable_i       (mem_we                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[5]               ),
      .ready_o              (ready[5]               ),
      .interrupt_request_o  (irq_req[5]             ),
      .interrupt_return_i   (irq_ret[5]             )
    );
  end
  else begin
    assign   rdata[5] = '0;
    assign   ready[5] = '0;
    assign irq_req[5] = '0;
  end

  if(PLATFORM_SUPPORT_UART_TX) begin
    uart_tx_sb_ctrl   tx_inst(
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[6]                 ),
      .write_enable_i       (mem_we                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[6]               ),
      .ready_o              (ready[6]               ),
      .tx_o                 (uart_tx                )
  );
  end
  else begin
    assign   rdata[6]   = '0;
    assign   ready[6]   = '0;
    assign   uart_tx    = 'z;
  end

  if(PLATFORM_SUPPORT_VGA) begin
    vga_sb_ctrl vga_inst(
      .*,
      .clk_i                (sysclk                 ),
      .vga_clk_i            (vga_clk                ),
`ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
      .x_i                  (vga_x_i                ),
      .y_i                  (vga_y_i                ),
`endif
      .rst_i                (core_rst               ),
      .req_i                (req[7]                 ),
      .write_enable_i       (mem_we                 ),
      .mem_be_i             (mem_be                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[7]               ),
      .ready_o              (ready[7]               )
    );
  end
  else begin
    assign   rdata[7] = '0;
    assign   ready[7] = '0;
  end

  if(PLATFORM_SUPPORT_TIMER) begin
    timer_sb_ctrl timer_inst(
      .clk_i                (sysclk                 ),
      .rst_i                (core_rst               ),
      .req_i                (req[8]                 ),
      .write_enable_i       (mem_we                 ),
      .write_data_i         (mem_wd                 ),
      .addr_i               (mem_addr               ),
      .read_data_o          (rdata[8]               ),
      .ready_o              (ready[8]               ),
      .interrupt_request_o  (irq_req[8]             )
    );
  end
  else begin
    assign   rdata[8] = '0;
    assign   ready[8] = '0;
    assign irq_req[8] = '0;
  end

  if(PLATFORM_SUPPORT_PROGRAMMER) begin
    bluster blust_inst(
      .clk_i                (sysclk                 ),
      .rst_i                (rst | jtag2bluster_rst ),
      .rx_i                 (rx_i                   ),
      .tx_o                 (bl_tx                  ),
      .instr_addr_o         (bl_instr_addr_o        ),
      .instr_wdata_o        (bl_instr_wdata_o       ),
      .instr_we_o           (bl_instr_we_o          ),
      .data_addr_o          (bl_data_addr_o         ),
      .data_wdata_o         (bl_data_wdata_o        ),
      .data_we_o            (bl_data_we_o           ),
      .core_reset_o         (bl2core_rst            )
    );
  end
  else begin
    assign bl_instr_addr_o  = '0;
    assign bl_instr_wdata_o = '0;
    assign bl_instr_we_o    = '0;
    assign bl_data_addr_o   = '0;
    assign bl_data_wdata_o  = '0;
    assign bl_data_we_o     = '0;
    assign bl_tx            = 'z;
    assign bl2core_rst      = rst;
  end


  if(PLATFORM_SUPPORT_JTAG) begin
    jtag_debug jtag_debug_inst(
      .trst_i               (trst                   ),
      .tck_i                (tck_i                  ),
      .tms_i                (tms_i                  ),
      .tdi_i                (tdi_i                  ),
      .tdo_o                (tdo_o                  ),
      .tdo_en_o             (tdo_en_o               ),

      .clk_i                (sysclk                 ),
      .rst_i                (rst                    ),

      .pc_i                 (instr_addr             ),
      .instr_i              (instr                  ),

      .mem_addr_i           (mem_addr               ),
      .mem_data_i           (core_we ?
                              core_wd : core_rd     ),
      .mem_we_i             (core_we                ),
      .mem_be_i             (mem_be                 ),

      .halt_o               (halt                   ),
      .step_o               (step                   ),
      .cpu_rst_o            (jtag2core_rst          ),
      .bluster_rst_o        (jtag2bluster_rst       )
    );
  end
  else begin
    assign halt             = '0;
    assign step             = '0;
    assign jtag2core_rst    = rst;
    assign jtag2bluster_rst = rst;
  end
//=====================================================
endmodule
