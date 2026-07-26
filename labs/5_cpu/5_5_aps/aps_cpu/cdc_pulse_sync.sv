module cdc_pulse_sync(
  input logic src_clk_i,
  input logic src_rst_i,
  input logic src_pulse_i,
  input logic dst_clk_i,
  input logic dst_rst_i,
  output logic dst_pulse_o
);

logic src_edge, dest_edge_sync1, dest_edge_sync2, dest_edge;
always_ff @(posedge src_clk_i or posedge src_rst_i) begin
  if(src_rst_i) begin
    src_edge <= 1'b0;
  end else begin
    src_edge <= src_edge ^ src_pulse_i;
  end
end

always_ff @(posedge dst_clk_i or posedge dst_rst_i) begin
  if(dst_rst_i) begin
    dest_edge_sync1 <= 1'b0;
  end else begin
    dest_edge_sync1 <= src_edge;
  end
end

always_ff @(posedge dst_clk_i or posedge dst_rst_i) begin
  if(dst_rst_i) begin
    dest_edge_sync2 <= 1'b0;
  end else begin
    dest_edge_sync2 <= dest_edge_sync1;
  end
end

always_ff @(posedge dst_clk_i or posedge dst_rst_i) begin
  if(dst_rst_i) begin
    dest_edge <= 1'b0;
  end else begin
    dest_edge <= dest_edge_sync2;
  end
end

assign dst_pulse_o = dest_edge ^ dest_edge_sync2;

endmodule