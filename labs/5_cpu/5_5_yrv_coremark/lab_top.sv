`include "config.svh"

`define BOOT_FROM_AUX_UART
`define NO_READMEMH_FOR_8_BIT_WIDE_MEM
`define USE_MEM_BANKS_FOR_BYTE_LINES

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    assign sound      = '0;
    assign uart_tx    = '1;

    //--------------------------------------------------------------------------
    // Invert reset
    wire reset_n = ~rst;

    //------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Slow clock button / switch

    wire slow_clk_mode = key[0];
    assign led[0] = muxed_clk;


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
         `ifdef INTEL_VERSION
             global i_global (.in (muxed_clk_raw), .out (muxed_clk));
        `else
             BUFG i_global (.I (muxed_clk_raw), .O (muxed_clk));
         `endif
    `endif

    //--------------------------------------------------------------------------
    // MCU inputs

    wire                 ei_req = 1'b0;                             // external int request
    wire                 nmi_req;         // non-maskable interrupt
    wire                 resetb  = reset_n;    // master reset
    wire                 ser_rxd = 1'b0;         // receive data input
    wire    [15:0] port4_in    = '0;
    wire    [15:0] port5_in    = '0;

    //--------------------------------------------------------------------------
    // MCU outputs

    wire                 debug_mode;    // in debug mode
    wire                 ser_clk;         // serial clk output (cks mode)
    wire                 ser_txd;         // transmit data output
    wire                 wfi_state;     // waiting for interrupt
    wire    [15:0] port0_reg;     // port 0
    wire    [15:0] port1_reg;     // port 1
    wire    [15:0] port2_reg;     // port 2
    wire    [15:0] port3_reg;     // port 3

    // Auxiliary UART receive pin

    `ifdef BOOT_FROM_AUX_UART
        wire        aux_uart_rx = uart_rx;
    `endif

    // Exposed memory bus for debug purposes

    wire        mem_ready;     // memory ready
    wire [31:0] mem_rdata;     // memory read data
    wire        mem_lock;        // memory lock (rmw)
    wire        mem_write;     // memory write enable
    wire [ 1:0] mem_trans;     // memory transfer type
    wire [ 3:0] mem_ble;         // memory byte lane enables
    wire [31:0] mem_addr;        // memory address
    wire [31:0] mem_wdata;     // memory write data

    wire [31:0] extra_debug_data;

    //--------------------------------------------------------------------------
    // MCU instantiation

    yrv_mcu
    # (.clk_frequency (clk_mhz * 1000 * 1000))
    i_yrv_mcu
    (.clk (muxed_clk), .*);

    //--------------------------------------------------------------------------
    // Pin assignments

    // The original board had port3_reg [13:8], debug_mode, wfi_state
    // assign led = port3_reg [11:8];

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

    wire [7:0] digit_from_mcu =
    {
        port1_reg [7],
        port1_reg [6],
        port1_reg [5],
        port1_reg [4],    
        port1_reg [3],
        port1_reg [2],
        port1_reg [1],
        port1_reg [0]
    };

    //--------------------------------------------------------------------------

    wire [7:0] abcdefgh_from_show_mode;
    wire [7:0] digit_from_show_mode;

    logic [15:0] display_number;



    always_comb
        casez (key)
        default : display_number = mem_addr  [31: 0];
        4'b0001? : display_number = mem_rdata [31: 0];
        4'b0010? : display_number = mem_wdata [31: 0];
        endcase


    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .number   ( display_number            ),
        .dots     ( w_digit' (0)              ),
        .abcdefgh ( abcdefgh_from_show_mode   ),
        .digit    ( digit_from_show_mode      )
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



    // 125Hz interrupt
    // 50,000,000 Hz / 125 Hz = 40,000 cycles ???

    logic [32:0] hz125_reg;
    logic                hz125_lat;

    assign   nmi_req        = hz125_lat || key[7];
    wire     hz125_lim = hz125_reg == 32'd299999;

    always_ff @ (posedge clk or negedge resetb)
        if (~ resetb)
        begin
            hz125_reg <= 32'd0;
            hz125_lat <= 1'b0;
        end
        else
        begin
            hz125_reg <= hz125_lim ? 32'd0 : hz125_reg + 1'b1;
            if(port3_reg[0])
                hz125_lat <=  hz125_lim;
            else
                hz125_lat <= 1'b0;
        end

//DOT NOT DOTED!
    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if ( 
            (y[2:0]== 3'b110) 
              &&
            (x[2:0] == 3'b110)
           )
        begin
               green = 32'hffff;
        end
    end

endmodule
