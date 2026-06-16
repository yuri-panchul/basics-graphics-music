`include "config.svh"

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

    //------------------------------------------------------------------------

       assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    import uart_pkg::*;

    localparam over_smpl    = 1'b0;        // 0: x16, 1: x8
    localparam stop_bits    = 1'b0;        // 0: 1 stop bit, 1: 2 stop bits
    localparam baudrate     = 115200;
    localparam uart_strb_hz = over_smpl ? (baudrate * 8) : (baudrate * 16);

    localparam fifo_width = 8;
    localparam fifo_depth = 16;

    localparam num_width = 16;

    //------------------------------------------------------------------------

    logic uart_strb;

    strobe_gen
    # (.clk_mhz (clk_mhz), .strobe_hz (uart_strb_hz))
    i_strobe_gen
    (
        .clk    ( clk       ),
        .rst    ( rst       ),
        .strobe ( uart_strb )
    );

    //------------------------------------------------------------------------

    logic       rx_vld;
    logic [7:0] rx_data;
    logic       rx_rdy;

    logic                    rx_fifo_push;
    logic                    rx_fifo_pop;
    logic [fifo_width - 1:0] rx_fifo_wr_data;
    logic [fifo_width - 1:0] rx_fifo_rd_data;
    logic                    rx_fifo_empty;
    logic                    rx_fifo_full;

    uart_receiver 
    # (.over_smpl (over_smpl), .stop_bits (stop_bits))
    i_uart_receiver (
        .clk         ( clk       ),
        .rst         ( rst       ),
        .uart_strb_i ( uart_strb ),
        .rx_vld_o    ( rx_vld    ),
        .rx_data_o   ( rx_data   ),
        .rx_rdy_i    ( rx_rdy    ),
        .rx_i        ( uart_rx   )
    );

    fifo 
    # (.width (fifo_width), .depth (fifo_depth))
    i_rx_fifo (
        .clk     ( clk             ),
        .rst     ( rst             ),
        .push    ( rx_fifo_push    ),
        .pop     ( rx_fifo_pop     ),
        .wr_data ( rx_fifo_wr_data ),
        .rd_data ( rx_fifo_rd_data ),
        .empty   ( rx_fifo_empty   ),
        .full    ( rx_fifo_full    )
    );

    assign rx_fifo_push    = rx_vld & rx_rdy;
    assign rx_fifo_wr_data = rx_data;
    assign rx_rdy          = ~rx_fifo_full;
    
    //------------------------------------------------------------------------

    logic                   tok_vld;
    logic                   tok_rdy;
    logic                   tok_is_num;
    logic [num_width - 1:0] tok_num;
    opcode_t                tok_op;

    logic                   lifo_push;
    logic                   lifo_pop;
    logic                   lifo_pop2;
    logic [num_width - 1:0] lifo_wr_data;
    logic [num_width - 1:0] lifo_tos;
    logic [num_width - 1:0] lifo_nos;
    logic                   lifo_empty;
    logic                   lifo_full;
    logic                   lifo_has_two;

    logic                   res_vld;
    logic [num_width - 1:0] res_data;

    ascii2tok 
    # (.num_width (num_width))
    i_ascii2tok (
        .clk          ( clk             ),
        .rst          ( rst             ),
        .fifo_pop_o   ( rx_fifo_pop     ),
        .fifo_data_i  ( rx_fifo_rd_data ),
        .fifo_empty_i ( rx_fifo_empty   ),
        .tok_vld_o    ( tok_vld         ),
        .tok_rdy_i    ( tok_rdy         ),
        .tok_is_num_o ( tok_is_num      ),
        .tok_num_o    ( tok_num         ),
        .tok_op_o     ( tok_op          )
    );

    lifo 
    # (.width (num_width), .depth (fifo_depth))
    i_lifo (
        .clk      ( clk          ),
        .rst      ( rst          ),
        .push     ( lifo_push    ),
        .pop      ( lifo_pop     ),
        .pop2     ( lifo_pop2    ),
        .wr_data  ( lifo_wr_data ),
        .tos      ( lifo_tos     ),
        .nos      ( lifo_nos     ),
        .empty    ( lifo_empty   ),
        .full     ( lifo_full    ),
        .has_two  ( lifo_has_two )
    );

    calc 
    # (.num_width (num_width))
    i_calc (
        .clk            ( clk          ),
        .rst            ( rst          ),
        .tok_vld_i      ( tok_vld      ),
        .tok_rdy_o      ( tok_rdy      ),
        .tok_is_num_i   ( tok_is_num   ),
        .tok_num_i      ( tok_num      ),
        .tok_op_i       ( tok_op       ),
        .lifo_push_o    ( lifo_push    ),
        .lifo_pop_o     ( lifo_pop     ),
        .lifo_pop2_o    ( lifo_pop2    ),
        .lifo_wr_data_o ( lifo_wr_data ),
        .lifo_tos_i     ( lifo_tos     ),
        .lifo_nos_i     ( lifo_nos     ),
        .lifo_empty_i   ( lifo_empty   ),
        .lifo_full_i    ( lifo_full    ),
        .lifo_has_two_i ( lifo_has_two ),
        .res_vld_o      ( res_vld      ),
        .res_data_o     ( res_data     )
    );

    //------------------------------------------------------------------------

    logic [w_digit * 4 - 1:0] display_number;

    always_ff @(posedge clk or posedge rst) begin 
        if (rst) 
            display_number <= '0; 
        else if (res_vld)
            display_number <= (w_digit * 4)'(res_data);
    end

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .number   ( display_number            ),
        .dots     ( w_digit' (0)              ),
        .abcdefgh ( abcdefgh                  ),
        .digit    ( digit                     )
    );

endmodule
