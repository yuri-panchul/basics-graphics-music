module sw_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,  // не используется, добавлен для
                                     // совместимости с системной шиной
  output logic [31:0] read_data_o,
  output logic        ready_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
  input logic [15:0]  sw_i
);
assign ready_o = '1;
logic [15:0] sw;
logic [15:0] sw_prev;

always_ff @(posedge clk_i) begin
    if(rst_i) begin
        sw_prev <= '0;
    end
    else begin
        sw_prev <= sw;
    end
end

always_ff @(posedge clk_i) begin
    if(rst_i) begin
        interrupt_request_o <= '0;
    end
    else if(sw != sw_prev) begin
        interrupt_request_o <= '1;
    end
    else if(interrupt_return_i) begin
        interrupt_request_o <= '0;
    end
end

logic read_req;
assign read_req = req_i & !write_enable_i;

always_ff @(posedge clk_i) begin
    if(rst_i) begin
        read_data_o <= '0;
    end
    else if(read_req && (addr_i == 32'h0)) begin
        read_data_o <= sw;
    end
end

debouncer debouncer_sw[15:0] (
    .*,
    .din_i(sw_i),
    .dout_o(sw)
);

endmodule
