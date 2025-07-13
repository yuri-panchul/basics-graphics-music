
module instruction_ram
#(
    parameter SIZE = 256
)
(
    input logic         clk,

    input  logic        mem_valid,
    output logic        mem_ready,

    input  logic [31:0] mem_addr,
    input  logic [3:0]  mem_wstrb,

    output logic [31:0] mem_rdata,
    input  logic [31:0] mem_wdata
);
    logic [31:0] memory [0:SIZE - 1];
    logic mem_write, mem_read;

    assign mem_write = | mem_wstrb;
    assign mem_read  = ~ mem_write;

    initial $readmemh ("program.hex", memory);

    always @(posedge clk) begin: blk_mem_read
		if (mem_valid & mem_read)
            mem_rdata <= memory[mem_addr >> 2];
	end

    logic [31:0] write_data;

    always_comb begin : blk_mem_write_data
        write_data = memory[mem_addr >> 2];

        if (mem_wstrb[0]) write_data[ 7: 0] = mem_wdata[ 7: 0];
        if (mem_wstrb[1]) write_data[15: 8] = mem_wdata[15: 8];
        if (mem_wstrb[2]) write_data[23:16] = mem_wdata[23:16];
        if (mem_wstrb[3]) write_data[31:24] = mem_wdata[31:24];
    end

    always @(posedge clk) begin: blk_mem_write
		if (mem_valid & mem_write) begin
            memory[mem_addr >> 2] <= write_data;
		end
	end

    always_ff @(posedge clk) begin: blk_mem_read_ready_dly
        mem_ready <= mem_valid;
    end

endmodule
