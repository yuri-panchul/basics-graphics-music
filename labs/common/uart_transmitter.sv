//------------------------------------------------------------------------
//
//  UART TRANSMITTER:
//
//  This module sends single data frame of arbitrary size over single wire.
//
//  Data are latched when both ready and valid are active
//
//  Ready signal is produced when last STOP bit is being transferred.
//
//  Copyright (C) 2023 Ruslan Zalata <rz@fabmicro.ru>
//
//  SPDX-License-Identifier: BSD-2-Clause
//
// Usage example as follows:
//
/*
    wire [7:0] test_data[7];
    assign test_data[0] = "H";
    assign test_data[1] = "e";
    assign test_data[2] = "l";
    assign test_data[3] = "l";
    assign test_data[4] = "o";
    assign test_data[5] = "\r";
    assign test_data[6] = "\n";
    wire valid_ready;
    wire [7:0] data;
    reg  [7:0] ptr;

    uart_transmitter # (.clk_mhz(clk_mhz), .baud_rate(115200), .data_length(8), .need_parity(0), .stop_bits(1))
    i_uart_tx (.clk(clk), .rst(rst), .data(data), .valid(valid_ready), .ready(valid_ready), .tx(uart_tx));

    assign data = test_data[ptr];

    always @ (posedge clk or posedge rst)
    begin
        if(rst)
                ptr <= 0;
        else
        if(valid_ready)
        begin
                ptr <= ptr + 'd1;
                if(ptr == 'd6)
                        ptr <= 'd0;
        end
    end

*/
//------------------------------------------------------------------------


module uart_transmitter
# (
    parameter clk_mhz = 50,
              baud_rate = 115200,
              data_length = 8,
              need_parity = 0, // 0 - no parity, 1 - even, 2 - odd
              stop_bits = 1
)
(
    input                        clk,
    input                        rst,
    input  [data_length - 1:0]   data,
    input                        valid,
    output                       ready,
    output logic                 tx
);

    localparam S_IDLE   = 3'd0,
               S_START  = 3'd1,
               S_XMIT   = 3'd2,
               S_PARITY = 3'd3,
               S_STOP   = 3'd4;

    localparam UART_LOGIC_1 = 1'b1,
               UART_LOGIC_0 = 1'b0;

    logic [2:0] state;
    logic [4:0] bitnum;
    logic [data_length - 1:0] data_buffer;

    localparam bclk_top = clk_mhz * 1000000 / baud_rate;
    localparam w_bclk_cnt = $clog2(bclk_top) + 1;

    logic [w_bclk_cnt - 1:0] bclk_cnt;
    logic bclk_stb;

    logic parity;

    // Generate tx baud rate clock strobe

    always_ff @ (posedge clk or posedge rst)
        if(rst)
            bclk_cnt <= '0;
        else begin
            bclk_cnt <= bclk_cnt + w_bclk_cnt' (1);
            if (bclk_cnt == bclk_top)
                    bclk_cnt <= '0;
        end

    assign bclk_stb = (bclk_cnt == bclk_top);

    // Generate ready signal either if FSM is idleing, or every last STOP bit
    // but only once in every bclk.

    assign ready = (state == S_IDLE) ? 'b1 :
                   ((state == S_STOP) && (bitnum == stop_bits)
                                      && (bclk_cnt == bclk_top)) ? 'b1 : 'b0;

    // Modulate output TX signal depending on state and data

    always_comb
        case (state)
            S_IDLE:    tx = UART_LOGIC_1;
            S_START:   tx = UART_LOGIC_0;
            S_XMIT:    tx = data_buffer[bitnum];
            S_PARITY:  tx = parity ^ (need_parity - 1);
            S_STOP:    tx = UART_LOGIC_1;
            default:   tx = UART_LOGIC_1;
        endcase

    // Perform state machine transitions

    always_ff @ (posedge clk or posedge rst)
        if(rst)
        begin
            state <= S_IDLE;
            parity <= 'd0;
            bitnum <= 'd0;
        end
        else
            begin
                case (state)
                    S_IDLE:    if (valid)
                                   state <= S_START;

                    S_START:   if (bclk_stb)
                                   state <= S_XMIT;

                    S_XMIT:    if (bclk_stb)
                               begin
                                   bitnum <= bitnum + 'd1;
                                   parity <= parity ^ data_buffer[bitnum];
                                   if (bitnum == data_length - 1)
                                   begin
                                       bitnum <= 0; // preparation for sending STOP bits
                                       if (need_parity > 0)
                                           state <= S_PARITY;
                                       else
                                           state <= S_STOP;
                                   end
                               end

                    S_PARITY:  if (bclk_stb)
                                   state <= S_STOP;

                    S_STOP:    if (bclk_stb)
                               begin
                                   bitnum <= bitnum + 'd1;
                                   if (bitnum == stop_bits)
                                   begin
                                       // Get ready for next frame
                                       parity <= 'd0;
                                       bitnum <= 'd0;

                                       if(valid)
                                           state <= S_START;
                                       else
                                           state <= S_IDLE;
                                   end
                               end

                    default: state <= S_IDLE;

               endcase

               if(valid && ready)
                   data_buffer <= data;

           end

endmodule

