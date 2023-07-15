// Asynchronous reset here is needed for the FPGA board we use

module top
# (
    parameter clk_frequency       = 50 * 1000 * 1000,
              baud_rate           = 115200,
              timeout_in_seconds  = 10
)
(
    input        clk,
    input        reset_n,

    input  [3:0] key_sw,
    output [3:0] led,

    output [7:0] abcdefgh,
    output [3:0] digit,

    output       buzzer,

    output       hsync,
    output       vsync,
    output [2:0] rgb,

    input        rx
);

    wire reset = ~ reset_n;

    assign buzzer = 1'b1;
    assign hsync  = 1'b1;
    assign vsync  = 1'b1;
    assign rgb    = 3'b0;

    wire       byte_valid;
    wire [7:0] byte_data;

    uart_receiver
    # (
        .clk_frequency ( clk_frequency ),
        .baud_rate     ( baud_rate     )
    )
    receiver (.*);

    wire        word_valid;
    wire [31:0] word_address;
    wire [31:0] word_data;

    wire        busy;
    wire        error;

    hex_parser
    # (
        .clk_frequency       ( clk_frequency      ),
        .timeout_in_seconds  ( timeout_in_seconds )
    )
    parser
    (
        .in_valid     ( byte_valid   ),
        .in_char      ( byte_data    ),

        .out_valid    ( word_valid   ),
        .out_address  ( word_address ),
        .out_data     ( word_data    ),

        .*
    );

    assign led = ~ { byte_valid, word_valid, busy, error };

    logic [31:0] last_bytes;

    always @ (posedge clk or posedge reset)
        if (reset)
            last_bytes <= '0;
        else if (byte_valid)
            last_bytes <= { last_bytes [23:0], byte_data };

    logic [31:0] last_address;
    logic [31:0] last_word;

    always @ (posedge clk or posedge reset)
        if (reset)
        begin
            last_address <= '0;
            last_word    <= '0;
        end
        else if (word_valid)
        begin
            last_address <= word_address;
            last_word    <= word_data;
        end

    logic [15:0] number;

    always_comb
        case (key_sw)
        default: number = last_bytes   [15: 0];
        4'b0111: number = last_bytes   [31:16];

        4'b1011: number = last_word    [31:16];
        4'b1101: number = last_word    [15: 0];
        4'b1110: number = last_address [15: 0];

        4'b0011: number = word_data    [31:16];
        4'b1001: number = word_data    [15: 0];
        4'b1100: number = word_address [15: 0];
        endcase

    seven_segment_4_digits display (.*);

endmodule
