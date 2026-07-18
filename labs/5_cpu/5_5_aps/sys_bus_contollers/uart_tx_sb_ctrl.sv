module uart_tx_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic          clk_i,
  input  logic          rst_i,
  input  logic [31:0]   addr_i,
  input  logic          req_i,
  input  logic [31:0]   write_data_i,
  input  logic          write_enable_i,
  output logic [31:0]   read_data_o,
  output logic          ready_o,

/*
    Часть интерфейса модуля, отвечающая за подключение передающему,
    входные данные по UART
*/
  output logic          tx_o
);
  assign ready_o = 1'b1;

  logic [16:0] baudrate;
  logic parity_en;
  logic [1:0] stopbit;
  logic [7:0] data;
  logic busy, busy_o, valid;

  logic write_req; logic read_req;
  assign write_req = req_i & write_enable_i;
  assign read_req = req_i & !write_enable_i;
  logic rst;
  assign rst = rst_i | (write_req & (addr_i == 32'h24) && (write_data_i == 32'h1));

  always_ff @(posedge clk_i) begin
    if(rst) begin
      data <= '0;
    end
    else if(write_req & (addr_i == 32'h0)) begin
      data <= write_data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst) begin
      baudrate <= 17'd9600;
    end
    else if(write_req & (addr_i == 32'hc)) begin
      baudrate <= write_data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst) begin
      parity_en <= '0;
    end
    else if(write_req & (addr_i == 32'h10)) begin
      parity_en <= write_data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst) begin
      stopbit <= '0;
    end
    else if(write_req & (addr_i == 32'h14)) begin
      stopbit <= write_data_i;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst) begin
      busy <= '0;
    end
    else begin
      busy <= busy_o;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst) begin
      valid <= '0;
    end
    else if(write_req && (addr_i == 32'h0)) begin
      valid <= 1'b1;
    end
    else if(valid & !busy) begin
      valid <= 1'b0;
    end
  end

    uart_tx tx(
    .clk_i      (clk_i      ),
    .rst_i      (rst        ),
    .tx_o       (tx_o       ),
    .busy_o     (busy_o     ),
    .baudrate_i (baudrate   ),
    .parity_en_i(parity_en  ),
    .stopbit_i  (stopbit    ),
    .tx_data_i  (data       ),
    .tx_valid_i (valid      )
  );

  always_ff @(posedge clk_i) begin
    if(rst) begin
      read_data_o <= '0;
    end
    else if(read_req) begin
      case(addr_i)
        32'h00: read_data_o <= data;
        32'h08: read_data_o <= busy;
        32'h0c: read_data_o <= baudrate;
        32'h10: read_data_o <= parity_en;
        32'h14: read_data_o <= stopbit;
        default: read_data_o <= read_data_o;
      endcase
    end
  end
endmodule
