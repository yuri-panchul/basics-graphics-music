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

    wire               start = key [0];
    logic       [15:0] angle;

    wire               calc;
    wire               finish;

    wire signed [15:0] cos_out;
    wire signed [15:0] sin_out;

    cordic i_cordic
    (
        .clk     ( clk ),
        .rst     ( rst ),

        .start   ( start ),
        .angle   ( angle ),

        .calc    ( calc ),
        .finish  ( finish ),

        .cos_out ( cos_out ),
        .sin_out ( sin_out )
    );

    assign led [0] = finish;
    assign led [1] = calc;
    assign led [2] = start;
    assign led [7] = slow_clk;

    //------------------------------------------------------------------------

    localparam angle_array_index_width = 4,
               angle_array_length      = 1 << angle_array_index_width;

    `ifdef __ICARUS__

        logic [15:0] angle_const_array [0:angle_array_length - 1];

            assign angle_const_array [ 0] = 16'h0000; //  0 degrees
            assign angle_const_array [ 1] = 16'h0444; //  6 degrees
            assign angle_const_array [ 2] = 16'h0889; // 12 degrees
            assign angle_const_array [ 3] = 16'h0ccd; // 18 degrees
            assign angle_const_array [ 4] = 16'h1111; // 24 degrees
            assign angle_const_array [ 5] = 16'h1555; // 30 degrees
            assign angle_const_array [ 6] = 16'h199a; // 36 degrees
            assign angle_const_array [ 7] = 16'h1dde; // 42 degrees
            assign angle_const_array [ 8] = 16'h2222; // 48 degrees
            assign angle_const_array [ 9] = 16'h2666; // 54 degrees
            assign angle_const_array [10] = 16'h2aab; // 60 degrees
            assign angle_const_array [11] = 16'h2eef; // 66 degrees
            assign angle_const_array [12] = 16'h3333; // 72 degrees
            assign angle_const_array [13] = 16'h3777; // 78 degrees
            assign angle_const_array [14] = 16'h3bbc; // 84 degrees
            assign angle_const_array [15] = 16'h4000; // 90 degrees

    `else

        // New SystemVerilog syntax for array assignment

        wire [15:0] angle_const_array [0:angle_array_length - 1] =
        '{
            16'h0000, //  0 degrees
            16'h0444, //  6 degrees
            16'h0889, // 12 degrees
            16'h0ccd, // 18 degrees
            16'h1111, // 24 degrees
            16'h1555, // 30 degrees
            16'h199a, // 36 degrees
            16'h1dde, // 42 degrees
            16'h2222, // 48 degrees
            16'h2666, // 54 degrees
            16'h2aab, // 60 degrees
            16'h2eef, // 66 degrees
            16'h3333, // 72 degrees
            16'h3777, // 78 degrees
            16'h3bbc, // 84 degrees
            16'h4000  // 90 degrees
        };

    `endif

    //------------------------------------------------------------------------

    wire [angle_array_index_width - 1:0] angle_index;
    wire accept_start = start & ~calc;

    counter_with_enable
    # (angle_array_index_width)
    i_counter
    (
        .clk    ( clk ),
        .rst    ( rst ),
        .enable ( accept_start ),
        .cnt    ( angle_index )
    );

    assign angle = angle_const_array [angle_index];

    //------------------------------------------------------------------------

    logic [15:0] angle_sticky;
    logic [15:0] sin_out_sticky;

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            angle_sticky   <= '0;
            sin_out_sticky <= '0;
        end
        else
        begin
            if (accept_start)
                angle_sticky <= angle;

            if (finish)
                sin_out_sticky <= sin_out;
        end
    end

    seven_segment_display # (w_digit) i_display
    (
        .clk,
        .rst,
        .number ({ angle_sticky, sin_out_sticky }),
        .dots ('0),
        .abcdefgh,
        .digit
    );

endmodule

`endif