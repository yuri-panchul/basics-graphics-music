module bluster
(
  input   logic clk_i,
  input   logic rst_i,

  input   logic rx_i,
  output  logic tx_o,

  output logic [ 31:0] instr_addr_o,
  output logic [ 31:0] instr_wdata_o,
  output logic         instr_we_o,

  output logic [ 31:0] data_addr_o,
  output logic [ 31:0] data_wdata_o,
  output logic         data_we_o,

  output logic core_reset_o
);

import memory_pkg::INSTR_MEM_SIZE_BYTES;
import bluster_pkg::INIT_MSG_SIZE;
import bluster_pkg::FLASH_MSG_SIZE;
import bluster_pkg::ACK_MSG_SIZE;

 enum logic [2:0] {
  RCV_NEXT_COMMAND = 3'b000,
  INIT_MSG = 3'b001,
  RCV_SIZE = 3'b010,
  SIZE_ACK = 3'b011,
  FLASH = 3'b100,
  FLASH_ACK = 3'b101,
  WAIT_TX_DONE = 3'b110,
  FINISH = 3'b111}
state, next_state;

logic rx_busy, rx_valid, tx_busy, tx_valid;
 logic [7:0] rx_data, tx_data;

logic [5:0] msg_counter;
logic [31:0] size_counter, flash_counter;
logic [3:0] [7:0] flash_size, flash_addr;

logic send_fin, size_fin, flash_fin, next_round;

assign send_fin   = (msg_counter    ==  0)  && !tx_busy;
assign size_fin   = (size_counter   ==  0)  && !rx_busy;
assign flash_fin  = (flash_counter  ==  0)  && !rx_busy;
assign next_round = (flash_addr     != '1)  && !rx_busy;

logic [7:0] [7:0] flash_size_ascii, flash_addr_ascii;
// Блок generate позволяет создавать структуры модуля цикличным или условным
// образом. В данном случае, при описании непрерывных присваиваний была
// обнаружена закономерность, позволяющая описать четверки присваиваний в более
// общем виде, который был описан в виде цикла.
// Важно понимать, данный цикл лишь автоматизирует описание присваиваний и во
// время синтеза схемы развернется в четыре четверки непрерывных присваиваний.
genvar i;
generate
  for(i=0; i < 4; i=i+1) begin
    // Данная логика преобразовывает сигналы flash_size и flash_addr,
    // которые представляют собой "сырые" двоичные числа в ASCII-символы[1]

    // Разделяем каждый байт flash_size и flash_addr на два ниббла.
    // Ниббл — это 4 бита. Каждый ниббл можно описать 16-битной цифрой.
    // Если ниббл меньше 10 (4'ha), он описывается цифрами 0-9. Чтобы представить
    // его ascii-кодом, необходимо прибавить к нему число 8'h30
    // (ascii-код символа '0').
    // Если ниббл больше либо равен 10, он описывается буквами a-f. Для его
    // представления в виде ascii-кода, необходимо прибавить число 8'h57
    // (это уменьшенный на 10 ascii-код символа 'a' = 8'h61).
    assign flash_size_ascii[i*2]    = flash_size[i][3:0] < 4'ha ? flash_size[i][3:0] + 8'h30 :
                                                                  flash_size[i][3:0] + 8'h57;
    assign flash_size_ascii[i*2+1]  = flash_size[i][7:4] < 4'ha ? flash_size[i][7:4] + 8'h30 :
                                                                  flash_size[i][7:4] + 8'h57;

    assign flash_addr_ascii[i*2]    = flash_addr[i][3:0] < 4'ha ? flash_addr[i][3:0] + 8'h30 :
                                                                  flash_addr[i][3:0] + 8'h57;
    assign flash_addr_ascii[i*2+1]  = flash_addr[i][7:4] < 4'ha ? flash_addr[i][7:4] + 8'h30 :
                                                                  flash_addr[i][7:4] + 8'h57;
  end
endgenerate

logic [INIT_MSG_SIZE-1:0][7:0] init_msg;
// ascii-код строки "ready for flash starting from 0xflash_addr\n"
assign init_msg = { 8'h72, 8'h65, 8'h61, 8'h64, 8'h79, 8'h20, 8'h66, 8'h6F,
                    8'h72, 8'h20, 8'h66, 8'h6C, 8'h61, 8'h73, 8'h68, 8'h20,
                    8'h73, 8'h74, 8'h61, 8'h72, 8'h74, 8'h69, 8'h6E, 8'h67,
                    8'h20, 8'h66, 8'h72, 8'h6F, 8'h6D, 8'h20, 8'h30, 8'h78,
                    flash_addr_ascii, 8'h0a};

logic [FLASH_MSG_SIZE-1:0][7:0] flash_msg;
//ascii-код строки: "finished write 0xflash_size bytes starting from 0xflash_addr\n"
assign flash_msg = {8'h66, 8'h69, 8'h6E, 8'h69, 8'h73, 8'h68, 8'h65, 8'h64,
                    8'h20, 8'h77, 8'h72, 8'h69, 8'h74, 8'h65, 8'h20, 8'h30,
                    8'h78,      flash_size_ascii,      8'h20, 8'h62, 8'h79,
                    8'h74, 8'h65, 8'h73, 8'h20, 8'h73, 8'h74, 8'h61, 8'h72,
                    8'h74, 8'h69, 8'h6E, 8'h67, 8'h20, 8'h66, 8'h72, 8'h6F,
                    8'h6D, 8'h20, 8'h30, 8'h78,     flash_addr_ascii,
                    8'h0a};

uart_rx rx(
  .clk_i      (clk_i      ),
  .rst_i      (rst_i      ),
  .rx_i       (rx_i       ),
  .busy_o     (rx_busy    ),
  .baudrate_i (17'd115200 ),
  .parity_en_i(1'b1       ),
  .stopbit_i  (2'b1       ),
  .rx_data_o  (rx_data    ),
  .rx_valid_o (rx_valid   )
);

uart_tx tx(
  .clk_i      (clk_i      ),
  .rst_i      (rst_i      ),
  .tx_o       (tx_o       ),
  .busy_o     (tx_busy    ),
  .baudrate_i (17'd115200 ),
  .parity_en_i(1'b1       ),
  .stopbit_i  (2'b1       ),
  .tx_data_i  (tx_data    ),
  .tx_valid_i (tx_valid   )
);

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      state <= RCV_NEXT_COMMAND;
    end
    else begin
      state <= next_state;
    end
  end

  always_comb begin
    next_state = state;
    case(state)
      RCV_NEXT_COMMAND: begin
        if(size_fin) begin
          if(next_round) begin
            next_state = INIT_MSG;
          end
          else begin
            next_state = WAIT_TX_DONE;
          end
        end
      end
      INIT_MSG    : if(send_fin ) next_state = RCV_SIZE;
      RCV_SIZE    : if(size_fin ) next_state = SIZE_ACK;
      SIZE_ACK    : if(send_fin ) next_state = FLASH;
      FLASH       : if(flash_fin) next_state = FLASH_ACK;
      FLASH_ACK   : if(send_fin ) next_state = RCV_NEXT_COMMAND;
      WAIT_TX_DONE: if(!tx_busy ) next_state = FINISH;
      FINISH      : next_state = FINISH;
      default     : next_state = RCV_NEXT_COMMAND;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      size_counter <= 32'd4;
    end
    else begin
      case(state)
        RCV_SIZE, RCV_NEXT_COMMAND: size_counter <= size_counter - rx_valid;
        default: size_counter <= 32'd4;
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      flash_counter <= flash_size;
    end
    else begin
      case(state)
        FLASH: flash_counter <= flash_counter - rx_valid;
        default: flash_counter <= flash_size;
      endcase
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      msg_counter <= INIT_MSG_SIZE - 1;
    end
    else begin
      case(state)
        FLASH           : msg_counter <= FLASH_MSG_SIZE - 1;
        RCV_SIZE        : msg_counter <= ACK_MSG_SIZE - 1;
        RCV_NEXT_COMMAND: msg_counter <= INIT_MSG_SIZE - 1;
        INIT_MSG,
        SIZE_ACK,
        FLASH_ACK       : msg_counter <= msg_counter - tx_valid;
        default         : msg_counter <= msg_counter;
      endcase
    end
  end

  assign tx_valid = !tx_busy & (state inside {INIT_MSG, SIZE_ACK, FLASH_ACK});

  always_comb begin
    case(state)
      INIT_MSG  : tx_data = init_msg[msg_counter];
      SIZE_ACK  : tx_data = flash_size[msg_counter];
      FLASH_ACK : tx_data = flash_msg[msg_counter];
      default   : tx_data = '0;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      flash_size <= '0;
    end
    else begin
      flash_size <= ((state == RCV_SIZE) & rx_valid) ?
                    {flash_size[2:0], rx_data} :
                    flash_size;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      flash_addr <= '0;
    end
    else begin
      flash_addr <= ((state == RCV_NEXT_COMMAND) & rx_valid) ?
                     {flash_addr [2:0], rx_data} :
                      flash_addr ;
    end
  end


  assign core_reset_o = state != FINISH;


  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      instr_wdata_o <= '0;
      instr_we_o    <= '0;
      instr_addr_o  <= '0;
    end
    else if((state == FLASH) & rx_valid & (flash_addr < INSTR_MEM_SIZE_BYTES)) begin
      instr_wdata_o <= {instr_wdata_o[23:0], rx_data};
      instr_we_o    <= flash_counter[1:0] == 2'b01;
      instr_addr_o  <= flash_addr + flash_counter - 1'b1;
    end
    else begin
      instr_wdata_o <= instr_wdata_o;
      instr_we_o    <= 1'b0;
      instr_addr_o  <= instr_addr_o;
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      data_wdata_o <= '0;
      data_we_o    <= '0;
      data_addr_o  <= '0;
    end
    else if((state == FLASH) & rx_valid & (flash_addr >= INSTR_MEM_SIZE_BYTES)) begin
      data_wdata_o  <= {data_wdata_o[23:0], rx_data};
      data_we_o     <= flash_counter[1:0] == 2'b01;
      data_addr_o   <= flash_addr + flash_counter - 1'b1;
    end
    else begin
      data_wdata_o  <= data_wdata_o;
      data_we_o     <= 1'b0;
      data_addr_o   <= data_addr_o;
    end
  end

endmodule