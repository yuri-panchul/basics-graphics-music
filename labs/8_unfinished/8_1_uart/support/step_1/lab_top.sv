`include "config.svh"

//`ifndef SIMULATION

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
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

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

localparam  baud_rate           = 115200;
localparam  clk_frequency       = clk_mhz * 1000 * 1000;

`ifndef SIMULATION
    localparam  update_hz   = 1;
    localparam timeout_in_seconds = 1;
`else
    localparam  update_hz   = 4000000;
    localparam timeout_in_seconds = 10;
`endif


    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       //assign uart_tx    = '1;

    //------------------------------------------------------------------------


    wire       byte_valid;
    wire [7:0] byte_data;

    uart_receiver
    # (
        .clk_frequency ( clk_frequency ),
        .baud_rate     ( baud_rate     )
    )
    receiver (
        .clk,
        .reset        (  rst         ),
        .rx           (  uart_rx     ),
        .byte_valid,
        .byte_data
    );

    wire        tx_byte_ready;
    wire        tx_byte_valid;
    wire [7:0]  tx_byte_data;

    // uart_transmitter
    // # (
    //     .clk_frequency ( clk_frequency ),
    //     .baud_rate     ( baud_rate     )
    // )
    // transmitter (
    //     .clk,
    //     .reset          (  rst         ),
    //     .tx             (  uart_tx     ),
    //     .byte_ready     ( tx_byte_ready ),
    //     .byte_valid     ( tx_byte_valid ),
    //     .byte_data      ( tx_byte_data  )
    // );

    assign tx_byte_valid = byte_valid;
    assign tx_byte_data = byte_data;

    
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
        .clk            (   clk         ),
        .reset          (   rst         ),
        .in_valid       (   byte_valid  ),
        .in_char        (   byte_data   ),

        .out_valid      (   word_valid   ),
        .out_address    (   word_address ),
        .out_data       (   word_data    ),

        .busy,
        .error
    );
   
    assign led = ~ { byte_valid, word_valid, busy, error };
   
    logic [31:0] last_bytes;
   
    always @ (posedge clk or posedge rst)
        if (rst)
            last_bytes <= '0;
        else if (byte_valid)
            last_bytes <= { last_bytes [23:0], byte_data };
   
    logic [31:0] last_address;
    logic [31:0] last_word;
   
    always @ (posedge clk or posedge rst)
        if (rst)
        begin
            last_address <= '0;
            last_word    <= '0;
        end
        else if (word_valid)
        begin
            last_address <= word_address;
            last_word    <= word_data;
        end

logic [w_digit * 4 - 1:0] number;
logic [w_digit     - 1:0] dots;
   
assign dots = '0;

always_comb
    case (key)
    default: number = last_bytes   [15: 0];
    4'b0111: number = last_bytes   [31:16];

    4'b1011: number = last_word    [31:16];
    4'b1101: number = last_word    [15: 0];
    4'b1110: number = last_address [15: 0];

    4'b0011: number = word_data    [31:16];
    4'b1001: number = word_data    [15: 0];
    4'b1100: number = word_address [15: 0];
    endcase
   
    seven_segment_display 
    #(
        .w_digit    (       w_digit     ),
        .clk_mhz    (       clk_mhz     ),
        .update_hz  (       update_hz   )
    )
    display(
        .clk,
        .rst,
        .number,
        .dots,
        .abcdefgh,
        .digit
    );
   

endmodule


//`endif