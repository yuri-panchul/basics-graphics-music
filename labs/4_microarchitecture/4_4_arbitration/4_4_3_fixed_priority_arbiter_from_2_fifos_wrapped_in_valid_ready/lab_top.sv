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

    localparam width = 4, depth = 4;

    wire               a_valid;
    wire               a_ready;
    wire [width - 1:0] a_data;

    wire               b_valid;
    wire               b_ready;
    wire [width - 1:0] b_data;

    wire               out_valid;
    wire               out_ready;
    wire [width - 1:0] out_data;

    //------------------------------------------------------------------------

    generate
        if (w_key >= 3)
        begin : three_keys
            // For example Saulinx board

            assign a_valid   =   key [2];
            assign b_valid   =   key [1];
            assign out_ready = ~ key [0];  // is not pressed - ready is ON by default
        end
        else if (w_key >= 2 && w_sw > 0)
        begin : two_keys_and_switch
            // For example DE0-Lite board

            assign a_valid   =   key [0];  // Top key is pressed
            assign b_valid   =   key [1];  // Bottom key is pressed
            assign out_ready = ~ sw  [0];  // Switch is not ON
        end
        else
        begin : single_key
            assign a_valid   =   key [0];
            assign b_valid   =   key [0];
            assign out_ready = ~ key [0];
        end
    endgenerate

    //------------------------------------------------------------------------

    wire [width - 2:0] a_data_pre;

    counter_with_enable # (width - 1) i_a_counter
    (
        .clk    (slow_clk),
        .enable (a_valid & a_ready),
        .cnt    (a_data_pre),
        .*
    );

    assign a_data = { 1'b0, a_data_pre };  // 0, 1, 2, ... 7

    //------------------------------------------------------------------------

    wire [width - 2:0] b_data_pre;

    counter_with_enable # (width - 1) i_b_counter
    (
        .clk    (slow_clk),
        .enable (b_valid & b_ready),
        .cnt    (b_data_pre),
        .*
    );

    assign b_data = { 1'b1, b_data_pre };  // 8, 9, a, ... f

    //------------------------------------------------------------------------

    fixed_priority_arbiter_from_2_fifos_wrapped_in_valid_ready
    # (.width (width), .depth (depth))
    i_rra_from_fifos (.clk (slow_clk), .*);

    //------------------------------------------------------------------------

    localparam w_number = w_digit * 4;

    wire [7:0] abcdefgh_pre;

    seven_segment_display # (w_digit) i_display
    (
        .clk      (clk),
        .number   (w_number' ({ a_data, b_data, 4'd0, out_data })),
        .dots     ('0),
        .abcdefgh (abcdefgh_pre),
        .digit    (digit),
        .*
    );

    //------------------------------------------------------------------------

    localparam sign_ready_a   = 8'b10000000,
               sign_ready_b   = 8'b00000010,
               sign_ready_out = 8'b00010000,
               sign_nothing   = 8'b00000000;

    always_comb
        case (digit [3:0])
        4'b0001: abcdefgh = out_valid ? abcdefgh_pre : sign_nothing;

        4'b0010:
        begin
            abcdefgh = sign_nothing;

            if ( a_ready   ) abcdefgh |= sign_ready_a;
            if ( b_ready   ) abcdefgh |= sign_ready_b;
            if ( out_ready ) abcdefgh |= sign_ready_out;
        end

        4'b0100,
        4'b1000: abcdefgh = abcdefgh_pre;

        default: abcdefgh = sign_nothing;
        endcase

endmodule
