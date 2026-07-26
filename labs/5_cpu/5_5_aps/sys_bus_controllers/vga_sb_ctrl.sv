module vga_sb_ctrl (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        vga_clk_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [3:0]  mem_be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o,

  output logic [3:0]  vga_r_o,
  output logic [3:0]  vga_g_o,
  output logic [3:0]  vga_b_o,
`ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
  input  logic [11:0] x_i,
  input  logic [11:0] y_i
`else
  output logic        vga_hs_o,
  output logic        vga_vs_o
`endif
);
assign ready_o = 1'b1;
logic [31:0] char_map_wdata_i, col_map_wdata_i, char_tiff_wdata_i;
logic [ 9:0] char_map_addr_i, col_map_addr_i, char_tiff_addr_i;
logic [ 3:0] char_map_be_i, col_map_be_i, char_tiff_be_i;

logic [31:0] char_map_rdata_o, col_map_rdata_o, char_tiff_rdata_o;
logic char_map_we_i, char_map_req_i, col_map_we_i, col_map_req_i, char_tiff_we_i, char_tiff_req_i;

assign char_map_wdata_i = write_data_i;
assign col_map_wdata_i  = write_data_i;
assign char_tiff_wdata_i= write_data_i;
assign char_map_addr_i  = addr_i[11:2];
assign col_map_addr_i   = addr_i[11:2];
assign char_tiff_addr_i = addr_i[11:2];
assign char_map_be_i    = mem_be_i;
assign col_map_be_i     = mem_be_i;
assign char_tiff_be_i   = mem_be_i;

assign char_map_we_i    = write_enable_i & (addr_i[13:12] == 2'b00);
assign char_map_req_i   =          req_i & (addr_i[13:12] == 2'b00);
assign col_map_we_i     = write_enable_i & (addr_i[13:12] == 2'b01);
assign col_map_req_i    =          req_i & (addr_i[13:12] == 2'b01);
assign char_tiff_we_i   = write_enable_i & (addr_i[13:12] == 2'b10);
assign char_tiff_req_i  =          req_i & (addr_i[13:12] == 2'b10);

always_comb begin
  case(addr_i[13:12])
    2'b00: read_data_o = char_map_rdata_o;
    2'b01: read_data_o = col_map_rdata_o;
    2'b10: read_data_o = char_tiff_rdata_o;
    default: read_data_o = '0;
  endcase
end

vgachargen #(
  .CLK_FACTOR_25M(1)
)vga(.*);

endmodule