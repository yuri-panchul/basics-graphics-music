module ps2_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [31:0]  addr_i,
  input  logic         req_i,
  input  logic [31:0]  write_data_i,
  input  logic         write_enable_i,
  output logic [31:0]  read_data_o,
  output logic         ready_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему прием данных с клавиатуры
*/
  input  logic kclk_i,
  input  logic kdata_i
);
assign ready_o = 1'b1;
logic [7:0] keycode_o;
logic       keycode_valid_o;

logic [7:0] scan_code;
logic       scan_code_is_unread;

PS2Receiver ps2(.*);

logic read_req;
assign read_req = req_i & !write_enable_i;

logic write_req;
assign write_req = req_i & write_enable_i;

logic soft_reset, rst;
assign soft_reset = write_req && (addr_i == 32'h24) && (write_data_i == 32'd1);
assign rst = rst_i | soft_reset;


always_ff @(posedge clk_i) begin
  if(rst) begin
    scan_code <= '0;
  end
  else if(keycode_valid_o) begin
    scan_code <= keycode_o;
  end
end

always_ff @(posedge clk_i) begin
  if(rst) begin
    scan_code_is_unread <= '0;
  end
  else if(keycode_valid_o) begin
    scan_code_is_unread <= 1'b1;
  end
  else if((read_req && (addr_i == 32'h0)) | interrupt_return_i)
    scan_code_is_unread <= 1'b0;
  else begin
    scan_code_is_unread <= scan_code_is_unread;
  end
end

assign interrupt_request_o = scan_code_is_unread;

always_ff @(posedge clk_i) begin
  if(rst) begin
    read_data_o <= '0;
  end
  else if(read_req) begin
    case(addr_i)
      32'h0: read_data_o <= scan_code;
      32'h4: read_data_o <= scan_code_is_unread;
      default: read_data_o <= read_data_o;
    endcase
  end
end
endmodule