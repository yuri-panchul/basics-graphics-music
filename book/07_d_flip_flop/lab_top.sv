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

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    localparam w_in = 8;
    logic [w_in - 1:0] in;

    generate
        if (w_key < w_in && w_sw >= w_in)
        begin : use_switches
            assign in = w_in' (sw);
        end
        else
        begin : use_keys
            assign in = w_in' (key);
        end
    endgenerate

    localparam w_out = 8;
    logic [w_out - 1:0] out;
    assign led = w_led' (out);

    //------------------------------------------------------------------------

    wire my_rst = in [0];
    wire any_in = | (in [w_in - 1:1]);  // Same as "in [w_in - 1:1] != '0"

    assign out [0] = slow_clk;

    //------------------------------------------------------------------------

    wire  d = any_in;
    logic q;

    always_ff @ (posedge slow_clk)
        if (my_rst)
            q <= 1'b0;
        else
            q <= d;

    assign out [1] = q;

    //------------------------------------------------------------------------

    d_flip_flop i0
    (
        .clk     ( slow_clk ),
        .d       ( d        ),
        .q       ( out [2]  )
    );

    d_flip_flop_sync_rst i1
    (
        .clk     ( slow_clk ),
        .rst     ( my_rst   ),
        .d       ( d        ),
        .q       ( out [3]  )
    );

    d_flip_flop_async_rst i2
    (
        .clk     ( slow_clk ),
        .rst     ( my_rst   ),
        .d       ( d        ),
        .q       ( out [4]  )
    );

    //------------------------------------------------------------------------

    //  Pulse generator, 50 times a second

    logic enable;

    strobe_gen # (.clk_mhz (clk_mhz), .strobe_hz (1))
    i_strobe_gen (clk, rst, enable);

    d_flip_flop_sync_rst_and_enable i3
    (
        .clk     ( clk      ),  // Note this is not a slow_clk
        .rst     ( my_rst   ),
        .enable  ( enable   ),
        .d       ( d        ),
        .q       ( out [5]  )
    );

    // Exercise: Change the strobe generator frequency

    assign out [7:6] = '0;

endmodule
