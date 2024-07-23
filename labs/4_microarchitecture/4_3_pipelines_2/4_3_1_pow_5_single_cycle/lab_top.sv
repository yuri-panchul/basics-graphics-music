`include "config.svh"

`ifndef SIMULATION

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

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    localparam width = 12;

    // Upstream

    wire               up_vld   = key [1];
    wire               up_rdy;
    wire [width - 1:0] up_data;

    // Downstream

    wire               down_vld;
    wire               down_rdy = key [0];
    wire [width - 1:0] down_data;

    //--------------------------------------------------------------------------

    localparam max_cnt   = 5,
               cnt_width = $clog2 (max_cnt);

    logic [cnt_width - 1:0] cnt;

    always_ff @ (posedge slow_clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (up_vld & up_rdy)
            cnt <= (cnt == max_cnt ? '0 : cnt + 1'd1);

    assign up_data = width' (cnt);

    //--------------------------------------------------------------------------

    pow_5_single_cycle
    # (.width (width))
    pow_5
    (
        .clk        ( slow_clk  ),
        .rst        ( rst       ),

        .up_vld     ( up_vld    ),
        .up_rdy     ( up_rdy    ),
        .up_data    ( up_data   ),

        .down_vld   ( down_vld  ),
        .down_rdy   ( down_rdy  ),
        .down_data  ( down_data )
    );

    //--------------------------------------------------------------------------

    wire [7:0] abcdefgh_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      (clk),
        .number   ({ up_data [3:0], down_data [11:0] }),
        .dots     ('0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    localparam sign_nothing = 8'b00000000;

    assign abcdefgh =
          ( digit [3]   != 1'b0    & ~ up_rdy   )
        | ( digit [2:0] !=  3'b000 & ~ down_vld )
        |   digit [3:0] == 4'b0000
      ? sign_nothing : abcdefgh_pre;

    assign led = w_led' ({ up_vld, up_rdy, down_vld, down_rdy });

endmodule

`endif
