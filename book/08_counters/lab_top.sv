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

    //------------------------------------------------------------------------

    wire my_rst = in [0];

    //------------------------------------------------------------------------

    logic [w_led - 1:0] cnt1;

    always_ff @ (posedge slow_clk)
        if (my_rst)
            cnt1 <= '0;
        else
            cnt1 <= cnt1 + 1'd1;
            
    //------------------------------------------------------------------------

    logic [31:0] cnt2;

    always_ff @ (posedge clk)
        if (rst)
            cnt2 <= '0;
        else
            cnt2 <= cnt2 + 1'd1;

    wire [w_led - 1:0] out2_1 = cnt2 [31 -: w_led];
    wire [w_led - 1:0] out2_2 = cnt2 [23 -: w_led];
    wire [w_led - 1:0] out2_3 = cnt2 [19 -: w_led];

    //------------------------------------------------------------------------

    wire enable1 = cnt2 [19:0];

    // 2 ** 20 = (2 ** 10) * (2 ** 10) = 1024 * 1024 = approximate 1000000.
    // For 27 MHz clock: 
    // 27 MHz 27000000 / 2 ** 20 = 27 times a cnt2 [19:0] overflows.

    logic [w_led - 1:0] cnt3;

    always_ff @ (posedge clk)
        if (reset)
            cnt3 <= '0;
        else if (enable1)
            cnt3 <= cnt3 + 1'd1;

    //------------------------------------------------------------------------

    logic enable2;

    strobe_gen # (.clk_mhz (clk_mhz), .strobe_hz (5))
    i_strobe_gen (clk, rst, enable2);

    always_ff @ (posedge clk)
        if (reset)
            cnt4 <= '0;
        else if (enable2)
            cnt4 <= cnt4 + 1'd1;

    //------------------------------------------------------------------------

    localparam w_number = w_digit * 4;
    wire [w_number - 1:0] number = w_number' (cnt2);

    seven_segment_display # (.w_digit (w_digit)) i_7segment
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .number   ( number   ),
        .dots     ( '0       ),  // This syntax means "all 0s in the context"
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );

    //------------------------------------------------------------------------

    logic [w_led - 1:0] out;

    always_comb
        case (in [3:1])
        3'd1:    out = cnt1;
        3'd2:    out = out2_1;
        3'd3:    out = out2_2;
        3'd4:    out = out2_3;
        3'd5:    out = cnt3;
        3'd6:    out = cnt4;
        default: out = cnt1;

endmodule
