module timer_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o,
/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/
  output logic        interrupt_request_o
);
assign ready_o = '1;
logic [63:0] system_counter;
logic [63:0] delay;
enum logic [1:0] {OFF, NTIMES, FOREVER} mode, next_mode;
logic [31:0] repeat_counter;
logic [63:0] system_counter_at_start;

logic [63:0] counter_diff;
assign counter_diff = system_counter - system_counter_at_start;

logic write_req, mode_req, rst;
assign write_req = req_i & write_enable_i;
assign mode_req = write_req & (addr_i == 32'h10);
assign rst = rst_i | (write_req & (addr_i == 32'h24));


always_ff @(posedge clk_i) begin
  if(rst) begin
    system_counter <= '0;
  end
  else begin
    system_counter <= system_counter + 1'b1;
  end
end

always_ff @(posedge clk_i) begin
  if(rst) begin
    delay <= '0;
  end
  else if(write_req) begin
    if(addr_i == 32'h8) delay[31: 0] <= write_data_i;
    if(addr_i == 32'hc) delay[63:32] <= write_data_i;
  end
end

always_ff @(posedge clk_i) begin
  if(rst) begin
    mode <= OFF;
  end
  else begin
    mode <= next_mode;
  end
end

always_comb begin
  next_mode = mode;
  if(mode_req) begin
    case(write_data_i)
      32'd0: next_mode = OFF;
      32'd1: next_mode = NTIMES;
      32'd2: next_mode = FOREVER;
      default: next_mode = mode;
    endcase
  end
  else if((mode == NTIMES) & (repeat_counter == 0)) begin
    next_mode = OFF;
  end
end

always_ff @(posedge clk_i) begin
  if(rst) begin
    repeat_counter <= '0;
  end
  else if(write_req & (addr_i == 32'h14)) begin
    repeat_counter <= write_data_i;
  end
  else if((mode == NTIMES) & interrupt_request_o & (repeat_counter > 0)) begin
    repeat_counter <= repeat_counter - 1'b1;
  end
end

always_ff @(posedge clk_i) begin
  if(rst) begin
    system_counter_at_start <= '0;
  end
  else if(interrupt_request_o | ((next_mode != OFF) & mode_req)) begin
    system_counter_at_start <= system_counter;
  end
end

assign interrupt_request_o = (counter_diff == delay) & (mode != OFF);

always_ff @(posedge clk_i) begin
  if(rst) begin
    read_data_o <= '0;
  end
  else begin
    if(req_i & !write_enable_i) begin
      case(addr_i)
        32'h000: read_data_o <= system_counter[31:0];
        32'h004: read_data_o <= system_counter[63:32];
        32'h008: read_data_o <= delay[31:0];
        32'h00C: read_data_o <= delay[63:32];
        32'h010: read_data_o <= mode;
        32'h014: read_data_o <= repeat_counter;
        default: read_data_o <= read_data_o;
      endcase
    end
  end
end

endmodule