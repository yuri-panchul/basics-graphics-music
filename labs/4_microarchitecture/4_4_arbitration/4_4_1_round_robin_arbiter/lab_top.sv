   `define IMPLEMENTATION_1
// `define IMPLEMENTATION_2
// `define IMPLEMENTATION_3

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

    wire [7:0] req;

    generate
        if (w_key >= 3)
        begin : use_keys
            assign req = 8' (key);
        end
        else
        begin : use_keys_and_switches
            assign req = 8' ({ sw, key });
        end
    endgenerate

    wire [7:0] gnt1, gnt2;

    assign led      = w_led' (gnt1);
    assign abcdefgh = gnt2;
    assign digit    = w_digit' (gnt2);

    wire enable;

    //------------------------------------------------------------------------

    `ifdef IMPLEMENTATION_1

    // Generate a strobe signal 3 times a second

    strobe_gen
    # (.clk_mhz (clk_mhz), .strobe_hz (3))
    i_strobe_gen
    (
        .clk    ( clk    ),
        .rst    ( rst    ),
        .strobe ( enable )
    );

       arbiter_1_dumb_big_blob
    // arbiter_2_rotate_priority_rotate_verbose
    // arbiter_3_rotate_priority_case_rotate
    // arbiter_4_rotate_priority_3_assigns_rotate
    // arbiter_5_rotate_priority_rotate_brief
    arb1
    (
        .clk ( clk    ),
        .rst ( rst    ),
        .ena ( enable ),
        .req ( req    ),
        .gnt ( gnt1   )
    );

    // arbiter_1_dumb_big_blob
       arbiter_2_rotate_priority_rotate_verbose
    // arbiter_3_rotate_priority_case_rotate
    // arbiter_4_rotate_priority_3_assigns_rotate
    // arbiter_5_rotate_priority_rotate_brief
    arb2
    (
        .clk ( clk    ),
        .rst ( rst    ),
        .ena ( enable ),
        .req ( req    ),
        .gnt ( gnt2   )
    );

    `endif

    //------------------------------------------------------------------------

    `ifdef IMPLEMENTATION_2

    // New shorter System Verilog syntax

    strobe_gen # (.clk_mhz (clk_mhz), .strobe_hz (3))
    i_strobe_gen (.strobe (enable), .*);

    strobe_gen # (.width (24)) enable_src (.strobe (enable), .*);

    arbiter_3_rotate_priority_case_rotate arb1
        (.ena (enable), .gnt (gnt1), .*);

    arbiter_4_rotate_priority_3_assigns_rotate arb2
        (.ena (enable), .gnt (gnt2), .*);

    `endif

    //------------------------------------------------------------------------

    `ifdef IMPLEMENTATION_3

    // Passing signals by position - not recommended.
    // Can lead to difficult to debug bugs
    // in industrial code with many signals.

    strobe_gen # (.clk_mhz (clk_mhz), .strobe_hz (3))
    i_strobe_gen (clk, rst, enable);

    arbiter_1_dumb_big_blob
    arb1 (clk, rst, enable, req, gnt1);

    arbiter_5_rotate_priority_rotate_brief
    arb2 (clk, rst, enable, req, gnt2);

    `endif

endmodule
