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
       assign abcdefgh   = '0;
       assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
    // assign uart_tx    = '1;

    //------------------------------------------------------------------------

    localparam over_smpl    = 1'b0;        // 0: x16, 1: x8
    localparam stop_bits    = 1'b0;        // 0: 1 stop bit, 1: 2 stop bits
    localparam baudrate     = 115200;
    localparam uart_strb_hz = over_smpl ? (baudrate * 8) : (baudrate * 16);

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

    logic       tx_vld;
    logic [7:0] tx_data;
    logic       tx_rdy;

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

    uart_transceiver
    # (.over_smpl (over_smpl), .stop_bits (stop_bits))
    i_uart_transceiver (
        .clk          ( clk       ),
        .rst          ( rst       ),
        .uart_strb_i  ( uart_strb ),
        .tx_vld_i     ( tx_vld    ),
        .tx_data_i    ( tx_data   ),
        .tx_rdy_o     ( tx_rdy    ),
        .tx_o         ( uart_tx   )
    );

    assign rx_rdy = tx_rdy; 
    assign tx_vld = rx_vld;
    assign tx_data = rx_data;

endmodule
