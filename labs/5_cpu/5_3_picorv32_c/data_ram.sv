`include "config.svh"

// Unified instruction + data RAM for the PicoRV32 C lab.

module data_ram
#(
    parameter SIZE = 4096
)
(
    input  logic        clk,

    // CPU side (PicoRV32 native memory bus)

    input  logic        mem_valid,
    output logic        mem_ready,

    input  logic [31:0] mem_addr,
    input  logic [3:0]  mem_wstrb,

    output logic [31:0] mem_rdata,
    input  logic [31:0] mem_wdata,

    // Boot side (UART loader). Active only while the CPU is in reset.

    input  logic        boot_wr,
    input  logic [31:0] boot_addr,
    input  logic [31:0] boot_wdata
);
    localparam ADDR_MSB = $clog2 (SIZE) - 1;

    logic [31:0] memory [0:SIZE - 1];

    logic mem_write, mem_read;

    assign mem_write = mem_valid & (| mem_wstrb);
    assign mem_read  = mem_valid & ~ (| mem_wstrb);


    initial $readmemh ("../program.mem32", memory);

    //------------------------------------------------------------------------
    // Read (synchronous, one cycle latency)

    wire [ADDR_MSB:0] word_addr = mem_addr [2 +: ADDR_MSB + 1];

    always @ (posedge clk)
        if (mem_read)
            mem_rdata <= memory [word_addr];

    //------------------------------------------------------------------------
    // CPU write with byte strobes

    logic [31:0] write_data;

    always_comb
    begin
        write_data = memory [word_addr];

        if (mem_wstrb [0]) write_data [ 7: 0] = mem_wdata [ 7: 0];
        if (mem_wstrb [1]) write_data [15: 8] = mem_wdata [15: 8];
        if (mem_wstrb [2]) write_data [23:16] = mem_wdata [23:16];
        if (mem_wstrb [3]) write_data [31:24] = mem_wdata [31:24];
    end

    wire [ADDR_MSB:0] boot_word_addr = boot_addr [2 +: ADDR_MSB + 1];

    always @ (posedge clk)
        if (boot_wr)
            memory [boot_word_addr] <= boot_wdata;   // UART loader has priority
        else if (mem_write)
            memory [word_addr] <= write_data;

    //------------------------------------------------------------------------
    // Single wait state: ready one cycle after a valid access

    always_ff @ (posedge clk)
        mem_ready <= mem_valid & ~ mem_ready;

endmodule
