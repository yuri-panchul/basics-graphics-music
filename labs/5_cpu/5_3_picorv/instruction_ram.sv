
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

    initial $readmemh ("program.hex", memory);

    always @(posedge clk) begin: mem_read_write
		if (mem_valid) begin
            if      (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
            else if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
            else if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
            else if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
            else    mem_rdata <= memory[mem_addr >> 2];
		end
	end

    always_ff @(posedge clk) begin: mem_read_ready_dly
        mem_ready <= mem_valid;
    end

endmodule
