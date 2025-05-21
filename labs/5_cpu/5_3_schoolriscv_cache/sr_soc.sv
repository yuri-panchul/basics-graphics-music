//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Alexander Kirichenko
//  for systemverilog-homework project.
//

module sr_soc
#(
  parameter bit CACHE_EN = 1'b0 // 1 - enable cache, 0 - disable (block cl_hit signal in the sr_icache module)
)
(
    input           clk,        // clock
    input           rst,        // reset

    input   [31:0]  soc_data_i, // instruction memory address
    output  [31:0]  soc_addr_o, // instruction memory data

    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data
    
    output  [31:0]  cycleCnt_o  // clk counter for evaluation program time execution
);

    //instruction memory
    wire [31:0]  imAddr;   // instruction memory address
    wire [31:0]  imData;   // instruction memory data
    wire         im_req;
    wire         im_drdy;
    wire [31:0]  ext_addr;
    wire         ext_req;
    wire         ext_rsp;
    wire [127:0] ext_data;

    //data memory
    wire [31:0]  mem_addr;
    wire [31:0]  mem_data;
    wire         memWrite;

    wire cpu_im_req;
    assign im_req = init_im_req | cpu_im_req;

    sr_cpu cpu
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .regAddr    ( regAddr    ),
        .regData    ( regData    ),
        .im_req     ( cpu_im_req ),
        .imAddr     ( imAddr     ),
        .imData     ( imData     ),
        .im_drdy    ( im_drdy    ),  //cpu pc write enable
        .memAddr    ( mem_addr   ),
        .memData    ( mem_data   ),
        .memWrite   ( memWrite   )
    );

    sr_icache #(
        .CACHE_EN(CACHE_EN)
    )
    icache
    (
        .clk        (clk      ),
        .rst        (rst      ),
        .imem_req_i (im_req   ),
        .imAddr     (imAddr   ),
        .imData     (imData   ),
        .im_drdy    (im_drdy  ),
        .ext_addr_o (ext_addr ),
        .ext_req_o  (ext_req  ),
        .ext_rsp_i  (ext_rsp  ),
        .ext_data_i (ext_data )
    );

    sr_mem mem_ctrl
    (
        .clk        (clk        ),
        .rst        (rst        ),
        .ext_addr_i (ext_addr   ),
        .ext_req_i  (ext_req    ),
        .ext_rsp_o  (ext_rsp    ),
        .ext_data_o (ext_data   ),
        .rom_data_i (soc_data_i ),
        .rom_addr_o (soc_addr_o )
    );

    //------------------------------------------------------------------------

    // Reset detect for initial memory request
    logic d1;
    logic d2;
    wire init_im_req;

    always_ff @(posedge clk)
      if (rst) begin
        // For a testbench
        // All registers are zero by default on a FPGA
        d1 <= 0;
        d2 <= 0;
      end else begin
        d1 <= 1;
        d2 <= d1;
      end

    assign init_im_req = d1 & ~d2;

    //------------------------------------------------------------------------

    logic        cnt_en_ff;
    logic        cnt_clear_ff;

    // performance: cycle counter enable
    always_ff @(posedge clk)
        if (rst)
            cnt_en_ff <= 1'b0;
        else if (memWrite && (mem_addr == 32'hffff_0020)) // RARS MMIO addresses is 0xffff0000 - 0xffffffe0
            cnt_en_ff <= mem_data[0];

    // performance: cycle counter clear signal
    always_ff @(posedge clk)
        if (rst)
            cnt_clear_ff <= 1'b0;
        else if (memWrite && (mem_addr == 32'hffff_0120)) // RARS MMIO addresses is 0xffff0000 - 0xffffffe0
            cnt_clear_ff <= mem_data[0];

    // performance: cycle counter
    perf_cycle_counter i_cycle_cnt
    (
        .clk        (clk         ),
        .rst        (rst         ),
        .en_i       (cnt_en_ff   ),
        .clear_i    (cnt_clear_ff),
        .cycleCnt_o (cycleCnt_o  )
    );

endmodule
