module led_sb_ctrl (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        req_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    output logic [31:0] read_data_o,
    output logic        ready_o,

    output logic [15:0] led_o
);
  assign ready_o = '1;

  logic write_req;
  logic read_req;
  logic soft_rst, rst;

  assign write_req = req_i && write_enable_i;
  assign read_req  = req_i && !write_enable_i;
  assign soft_rst  = write_req && (addr_i == 32'h24) && (write_data_i == 32'd1);
  assign rst = soft_rst | rst_i;

  logic [15:0] led_val;
  logic        mode;
  
  always_ff @(posedge clk_i) begin
    if(rst) begin
      led_val <= '0;
    end
    else begin
      if(write_req & (addr_i == 32'h0)) begin
        led_val <= write_data_i[15:0];
      end
    end
  end
  
  always_ff @(posedge clk_i) begin
    if(rst) begin
      mode <= '0;
    end
    else begin
      if(write_req & (addr_i == 32'h4)) begin
        mode <= write_data_i[0];
      end
    end
  end
  
  logic [31:0] counter;
  always_ff @(posedge clk_i) begin
    if(rst | !mode | (counter >= 32'd20_000_000)) begin
      counter <= '0;
    end
    else if (mode) begin
      counter <= counter + 1'b1;
    end
  end
  
  assign led_o = counter < 32'd10_000_000 ? led_val : '0;
  
  always_ff @(posedge clk_i) begin
    if(rst) begin
      read_data_o <= '0;
    end
    else if(read_req) begin
      case(addr_i)
        32'h0: read_data_o <= {16'd0, led_val};
        32'h4: read_data_o <= {31'd0, mode};
      endcase
    end
  end
  
  
endmodule
