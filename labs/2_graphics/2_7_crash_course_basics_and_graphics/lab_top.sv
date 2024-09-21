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
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    // assign led [0] = key [0] ^ key [1];

    //------------------------------------------------------------------------

    logic [31:0] counter;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            counter <= '0;
        else
            counter <= counter + 1;

    assign led = w_led' (counter [25:22]);

    //------------------------------------------------------------------------

    // 4 bits per hexadecimal digit
    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                                 ),
        .rst      ( rst                                 ),
        .number   ( w_display_number' (counter [31:20]) ),
        .dots     ( w_digit' (0)                        ),
        .abcdefgh ( abcdefgh                            ),
        .digit    ( digit                               )
    );

    //------------------------------------------------------------------------
    // Static pattern

    /*

    wire [19:0] x_2 = x * x;

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (~ display_on)
        begin
        end
        else if (x > 100 & y > 100 & x < 150 & y < 400)  // Rectangle
        begin
            red   = '1;
            green = '0;
            blue  = '0;
        end
        `ifdef YOSYS
        else if ((x - 400) * (x - 400) + 2 * (y - 300) * (y - 300) < (100 * 100))  // Ellipse
        `else
        else if ((x - 400) ** 2  + 2 * (y - 300) ** 2 < 100 ** 2)  // Ellipse
        `endif
        begin
            red   = '0;
            green = '1;
            blue  = '0;
        end
        else if ((x_2 >> 9) < y)  // Parabola
        begin
            red   = '0;
            green = '0;
            blue  = '1;
        end
    end

    */

    //------------------------------------------------------------------------
    // Pattern 3 - dynamic

    /**/

    wire [9:0] dx = counter [27:18];
    wire [9:0] dy = counter [27:18];

    wire [19:0] x_2 = x * x;

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (x > 100 & (y - dy) > 100 & x < 150 & y < 400)  // Rectangle
        begin
            red   = '1;
            green = '0;
            blue  = '0;
        end
        `ifdef YOSYS
        else if ((x + dx - 400) * (x + dx - 400) + 2 * (y - 300) * (y - 300) < 100 * 100)  // Ellipse
        `else
        else if ((x + dx - 400) ** 2 + 2 * (y - 300) ** 2 < 100 ** 2)  // Ellipse
        `endif
        begin
            red   = '0;
            green = '1;
            blue  = '0;
        end
        `ifdef YOSYS
        else if (((((x + y) & 127) * ((x + y) & 127)) >> 8) < ((y - dy) & 127))  // Parabola
        `else
        else if (((((x + y) & 127) ** 2) >> 8) < ((y - dy) & 127))  // Parabola
        `endif
        begin
            red   = { 4 { counter [31] ^ x [6] } };
            green = { 4 { counter [30] ^ y [7] } };
            blue  = { 4 { counter [29]         } };
        end
        else
        begin
            red   = '1;
            green = '1;
            blue  = '0;
        end
    end

    /**/

    //------------------------------------------------------------------------

    /*

    wire [3:0] xc = x [w_x - 2 -: 4];
    wire [3:0] yc = y [w_y - 2 -: 4];

    always_comb
    begin
      red   = xc + xc + yc + dx;
      green = xc - yc - dy;
      blue  = { 4 { & key } };
    end

    */

endmodule
