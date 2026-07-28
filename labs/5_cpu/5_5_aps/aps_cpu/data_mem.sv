`include "config.svh"

module data_mem(
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [ 3:0] byte_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o
);
assign ready_o = 1'b1;
import memory_pkg::DATA_MEM_SIZE_WORDS;
import memory_pkg::DATA_MEM_FILE_NAME;
logic [31:0] ram [DATA_MEM_SIZE_WORDS];

generate
if(DATA_MEM_FILE_NAME != "")
initial $readmemh(DATA_MEM_FILE_NAME, ram);
endgenerate

logic [31:0] addr;
assign addr = addr_i[2+:$clog2(DATA_MEM_SIZE_WORDS)];

always_ff @(posedge clk_i) begin
  if(mem_req_i & !write_enable_i) begin
    read_data_o <= ram[addr];
  end
end

logic be[4];
assign be[0] = mem_req_i & write_enable_i & byte_enable_i[0];
assign be[1] = mem_req_i & write_enable_i & byte_enable_i[1];
assign be[2] = mem_req_i & write_enable_i & byte_enable_i[2];
assign be[3] = mem_req_i & write_enable_i & byte_enable_i[3];

always_ff @(posedge clk_i) begin
  for(int i = 0; i < 4; ++i) begin
    if(be[i]) ram[addr][i*8+: 8] <= write_data_i[i*8+: 8];
  end
end

endmodule
