`define INTEL_VERSION
`define CLK_FREQUENCY (50 * 1000 * 1000)

`include "yrv_mcu.v"

module top
(
  input              clk,
  input              reset_n,

  input        [3:0] key_sw,
  output       [3:0] led,

  output logic [7:0] abcdefgh,
  output logic [3:0] digit,

  output             buzzer,

  output             hsync,
  output             vsync,
  output       [2:0] rgb

  `ifdef BOOT_FROM_AUX_UART
  ,
  input              rx
  `endif
);

  //--------------------------------------------------------------------------
  // Unused pins

  assign buzzer = 1'b1;
  assign hsync  = 1'b1;
  assign vsync  = 1'b1;
  assign rgb    = 3'b0;

  //--------------------------------------------------------------------------
  // Slow clock button / switch

  wire slow_clk_mode = ~ key_sw [0];

  //--------------------------------------------------------------------------
  // MCU clock

  logic [22:0] clk_cnt;

  always @ (posedge clk or negedge reset_n)
    if (~ reset_n)
      clk_cnt <= '0;
    else
      clk_cnt <= clk_cnt + 1'd1;

  wire muxed_clk_raw
    = slow_clk_mode ? clk_cnt [22] : clk;

  wire muxed_clk;

  `ifdef SIMULATION
    assign muxed_clk = muxed_clk_raw;
  `else
    global i_global (.in (muxed_clk_raw), .out (muxed_clk));
  `endif

  //--------------------------------------------------------------------------
  // MCU inputs

  wire         ei_req;               // external int request
  wire         nmi_req   = 1'b0;     // non-maskable interrupt
  wire         resetb    = reset_n;  // master reset
  wire         ser_rxd   = 1'b0;     // receive data input
  wire  [15:0] port4_in  = '0;
  wire  [15:0] port5_in  = '0;

  //--------------------------------------------------------------------------
  // MCU outputs

  wire         debug_mode;  // in debug mode
  wire         ser_clk;     // serial clk output (cks mode)
  wire         ser_txd;     // transmit data output
  wire         wfi_state;   // waiting for interrupt
  wire  [15:0] port0_reg;   // port 0
  wire  [15:0] port1_reg;   // port 1
  wire  [15:0] port2_reg;   // port 2
  wire  [15:0] port3_reg;   // port 3

  // Auxiliary UART receive pin

  `ifdef BOOT_FROM_AUX_UART
  wire         aux_uart_rx = rx;
  `endif

  // Exposed memory bus for debug purposes

  wire         mem_ready;   // memory ready
  wire  [31:0] mem_rdata;   // memory read data
  wire         mem_lock;    // memory lock (rmw)
  wire         mem_write;   // memory write enable
  wire   [1:0] mem_trans;   // memory transfer type
  wire   [3:0] mem_ble;     // memory byte lane enables
  wire  [31:0] mem_addr;    // memory address
  wire  [31:0] mem_wdata;   // memory write data

  wire  [31:0] extra_debug_data;

  //--------------------------------------------------------------------------
  // MCU instantiation

  yrv_mcu i_yrv_mcu (.clk (muxed_clk), .*);

  //--------------------------------------------------------------------------
  // Pin assignments

  // The original board had port3_reg [13:8], debug_mode, wfi_state
  assign led = port3_reg [11:8];

  //--------------------------------------------------------------------------

  wire [7:0] abcdefgh_from_mcu =
  {
    port0_reg[6],
    port0_reg[5],
    port0_reg[4],
    port0_reg[3],
    port0_reg[2],
    port0_reg[1],
    port0_reg[0],
    port0_reg[7] 
  };

  wire [3:0] digit_from_mcu =
  {
    port1_reg [3],
    port1_reg [2],
    port1_reg [1],
    port1_reg [0]
  };

  //--------------------------------------------------------------------------

  wire [7:0] abcdefgh_from_show_mode;
  wire [3:0] digit_from_show_mode;

  logic [15:0] display_number;

  always_comb
    casez (key_sw)
    default : display_number = mem_addr  [15: 0];
    4'b110? : display_number = mem_rdata [15: 0];
    4'b100? : display_number = mem_rdata [31:16];
    4'b101? : display_number = mem_wdata [15: 0];
    4'b001? : display_number = mem_wdata [31:16];

    // 4'b101? : display_number = extra_debug_data [15: 0];
    // 4'b001? : display_number = extra_debug_data [31:16];
    endcase

  display_dynamic # (.n_dig (4)) i_display
  (
    .clk       (   clk                     ),
    .reset     ( ~ reset_n                 ),
    .number    (   display_number          ),
    .abcdefgh  (   abcdefgh_from_show_mode ),
    .digit     (   digit_from_show_mode    )
  );

  //--------------------------------------------------------------------------

  always_comb
    if (slow_clk_mode)
    begin
      abcdefgh = abcdefgh_from_show_mode;
      digit    = digit_from_show_mode;
    end
    else
    begin
      abcdefgh = abcdefgh_from_mcu;
      digit    = digit_from_mcu;
    end

  //--------------------------------------------------------------------------

  `ifdef OLD_INTERRUPT_CODE

  //--------------------------------------------------------------------------
  // 125Hz interrupt
  // 50,000,000 Hz / 125 Hz = 40,000 cycles

  logic [15:0] hz125_reg;
  logic        hz125_lat;

  assign ei_req    = hz125_lat;
  wire   hz125_lim = hz125_reg == 16'd39999;

  always_ff @ (posedge clk or negedge resetb)
    if (~ resetb)
    begin
      hz125_reg <= 16'd0;
      hz125_lat <= 1'b0;
    end
    else
    begin
      hz125_reg <= hz125_lim ? 16'd0 : hz125_reg + 1'b1;
      hz125_lat <= ~ port3_reg [15] & (hz125_lim | hz125_lat);
    end

  `endif

  //--------------------------------------------------------------------------
  // 8 KHz interrupt
  // 50,000,000 Hz / 8 KHz = 6250 cycles

  logic [12:0] khz8_reg;
  logic        khz8_lat;

  assign ei_req    = khz8_lat;
  wire   khz8_lim = khz8_reg == 13'd6249;

  always_ff @ (posedge clk or negedge resetb)
    if (~ resetb)
    begin
      khz8_reg <= 13'd0;
      khz8_lat <= 1'b0;
    end
    else
    begin
      khz8_reg <= khz8_lim ? 13'd0 : khz8_reg + 1'b1;
      khz8_lat <= ~ port3_reg [15] & (khz8_lim | khz8_lat);
    end

endmodule
