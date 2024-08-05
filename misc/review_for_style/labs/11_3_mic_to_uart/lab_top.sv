`include "config.svh"
`define ENABLE_TP1638
`define USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
`define ENABLE_INMP441

module lab_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 100
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,
    input                        mic_ready,
    output       [         15:0] sound,

    // UART
    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led      = '0;
    // assign abcdefgh = '0;
    // assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;
       assign sound    = '0;
    // assign uart_tx  = '1;


    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;

    localparam level_thrshld = 'h0400;

    logic [23:0] mic_avg[4];

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
        mic_avg[0]      <= '0;
        mic_avg[1]      <= '0;
        mic_avg[2]      <= '0;
        mic_avg[3]      <= '0;
        end
        else
        begin
            if (mic_ready && ~mic[23])
                begin
                    // Poor man's averaging: shift and sum positive values
                    // i.e. mic_avg[x] = mic_avg[x]/2 + mic_avg[x-1]/2
                    mic_avg[0] <= {1'b0, mic_avg[0][23:1]} + {1'b0, mic[23:1]};
                    mic_avg[1] <= {1'b0, mic_avg[1][23:1]} + {1'b0, mic_avg[0][23:1]};
                    mic_avg[2] <= {1'b0, mic_avg[2][23:1]} + {1'b0, mic_avg[1][23:1]};
                    mic_avg[3] <= {1'b0, mic_avg[3][23:1]} + {1'b0, mic_avg[2][23:1]};
                end
        end

    // Show mic average level on the 7-seg display

    logic [w_number - 1:0] number;

    seven_segment_display # (w_digit, clk_mhz, 16)
    i_7segment (.number (w_number' (number)), .*);

    always_ff @ (posedge clk)
        if(!key[0])
            if(mic_avg[3] > level_thrshld)
                number <= {8'd0, 24'(mic_avg[3])};
            else
                number <= {8'd0, 24'(0)};

    // Send mic values to UART, convert to 6-nibble (24 bit) hex string first with trailing \r\n

    wire uart_valid;
    wire uart_ready;
    wire [7:0] uart_data;
    reg  [7:0] sample_string_ptr;
    reg  [7:0] sample_string[8];

    // We use set baudrate to 921600 which allows transmitting ~11000 samples per second
    // Also we use two STOP bits at datarate this high

    uart_transmitter # (.clk_mhz(clk_mhz), .baud_rate(921600), .data_length(8), .need_parity(0), .stop_bits(2))
    i_uart_tx (.clk(clk), .rst(rst), .data(uart_data), .valid(uart_valid), .ready(uart_ready), .tx(uart_tx));

    assign uart_data = sample_string[sample_string_ptr];

    function [7:0] bin2ascii (input [3:0] bin);
        if(bin > 9)
            bin2ascii = {4'h4, 4'(bin - 9)};
        else
            bin2ascii = {4'h3, bin};
    endfunction

    // Below divider is used to reduce clock a little to get things sattle
    // Not doing so may cause data corruption on high freq boards

    reg [1:0] clk_div;
    always @ (posedge clk or posedge rst)
    begin
        if(rst)
           clk_div <= 0;
        else
           clk_div <= clk_div + 1;
    end

    assign uart_valid = (uart_ready && clk_div==0) ? 'b1 : 'b0;

    always @ (posedge clk or posedge rst)
    begin
        if(rst)
    begin
            sample_string_ptr <= 'd0;
            sample_string[0] <= "B";
            sample_string[1] <= "E";
            sample_string[2] <= "G";
            sample_string[3] <= "I";
            sample_string[4] <= "N";
            sample_string[5] <= "!";
            sample_string[6] <= "\r";
            sample_string[7] <= "\n";
    end else
        if(uart_valid)
        begin
            sample_string_ptr <= sample_string_ptr + 'd1;
            if(sample_string_ptr == 'd7)
            begin
                sample_string_ptr <= 'd0;
                sample_string[0] <= bin2ascii(mic[23:20]);
                sample_string[1] <= bin2ascii(mic[19:16]);
                sample_string[2] <= bin2ascii(mic[15:12]);
                sample_string[3] <= bin2ascii(mic[11:8]);
                sample_string[4] <= bin2ascii(mic[7:4]);
                sample_string[5] <= bin2ascii(mic[3:0]);
                sample_string[6] <= "\r";
                sample_string[7] <= "\n";
            end
        end
    end

endmodule

