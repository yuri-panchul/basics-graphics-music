`include "config.svh"

module top
# (
    parameter clk_mhz   = 50,
              pixel_mhz = 25,
              w_key     = 4,
              w_sw      = 8,
              w_led     = 8,
              w_digit   = 8,
              w_gpio    = 100,
              w_red     = 4,
              w_green   = 4,
              w_blue    = 4
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

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,
    output                       display_on,
    output                       pixel_clk,

    input                        uart_rx,
    output                       uart_tx,

    input        [         23:0] mic,
    output       [         15:0] sound,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

       assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign vsync      = '0;
       assign hsync      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign display_on = '0;
       assign pixel_clk  = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire [ 4:0]  regAddr;  // debug access reg address
    wire [31:0]  regData;  // debug access reg data
    
    wire [31:0]  ext_addr;
    wire         ext_req;
    wire         ext_rsp;
    wire [127:0] ext_data;
    wire [31:0]  rom_data;
    wire [31:0]  rom_addr;

    wire         im_req;
    wire [31:0]  imAddr;   // instruction memory address
    wire [31:0]  imData;   // instruction memory data
    wire         im_drdy;

    sr_cpu cpu
    (
        .clk        ( slow_clk ),
        .rst        ( rst      ),
        .regAddr    ( regAddr  ),
        .regData    ( regData  ),
        .im_req     ( im_req   ),
        .imAddr     ( imAddr   ),
        .imData     ( imData   ),
        .im_drdy    ( im_drdy  ),
        .addr_o     ( mem_addr ),
        .data_o     ( mem_data ),
        .memWrite_o ( memWrite )
    );

    sr_icache #(
    .CACHE_EN(CACHE_EN)
    ) sm_icache (
        .clk        (clk     ),
        .rst_n      (rst     ),
        .imem_req_i (im_req  ),
        .imAddr     (imAddr  ),
        .imData     (imData  ),
        .im_drdy    (im_drdy ),
        .ext_addr_o (ext_addr),
        .ext_req_o  (ext_req ),
        .ext_rsp_i  (ext_rsp ),
        .ext_data_i (ext_data)
    );

    sr_mem mem_ctrl(
        .clk        (slow_clk ),
        .rst_n      (rst      ),
        .ext_addr_i (ext_addr ),
        .ext_req_i  (ext_req  ),
        .ext_rsp_o  (ext_rsp  ),
        .ext_data_o (ext_data ),
        .rom_data_i (rom_data ),
        .rom_addr_o (rom_addr )
    );
    
    instruction_rom # (.SIZE (64)) rom
    (
        .a       ( rom_addr ),
        .rd      ( rom_data )
    );

    //------------------------------------------------------------------------

    logic        cnt_en_ff;
    logic        cnt_clear_ff;
    wire  [31:0] cycleCnt_o;

    // performance: cycle counter enable
    always_ff @(posedge clk or negedge rst_n)
        if (~rst_n)
            cnt_en_ff <= 1'b0;
        else if (memWrite && (mem_addr == 32'h200))
            cnt_en_ff <= mem_data[0];

    // performance: cycle counter clear signal
    always_ff @(posedge clk or negedge rst_n)
        if (~rst_n)
            cnt_clear_ff <= 1'b0;
        else if (memWrite && (mem_addr == 32'h201))
            cnt_clear_ff <= mem_data[0];

    // performance: cycle counter
    perf_cycle_counter i_cycle_cnt (
        .clk        (slow_clk    ),
        .rst        (rst         ),
        .en_i       (cnt_en_ff   ),
        .clear_i    (cnt_clear_ff),
        .cycleCnt_o (cycleCnt_o  )
    );

    //------------------------------------------------------------------------

    assign regAddr = 5'd10;  // a0

    localparam w_number = w_digit * 4;

    wire [w_number - 1:0] number
        = w_number' ( cycleCnt_o );

    seven_segment_display
    # (
        .w_digit  ( w_digit  ),
        .clk_mhz  ( clk_mhz  )
    )
    display
    (
        .clk      ( clk      ),
        .rst      ( rst      ),

        .number   ( number   ),
        .dots     ( '0       ),

        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

endmodule
