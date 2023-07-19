`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 20
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [          3:0] red,
    output logic [          3:0] green,
    output logic [          3:0] blue,

    input        [         23:0] mic,

    // General-purpose Input/Output

    inout  logic [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led      = '0;
       assign abcdefgh = '0;
       assign digit    = '0;
    // assign vsync    = '0;
    // assign hsync    = '0;
    // assign red      = '0;
    // assign green    = '0;
    // assign blue     = '0;

    //------------------------------------------------------------------------

    // assign led [0] = key [0] ^ key [1];

    //------------------------------------------------------------------------

    logic [31:0] counter;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            counter <= '0;
        else
            counter <= counter + 1;

    assign led = counter [25:22];

    //------------------------------------------------------------------------

    wire display_on;

    wire [9:0] x;
    wire [9:0] y;

    vga
    # (
        .HPOS_WIDTH ( 10      ),
        .VPOS_WIDTH ( 10      ),

        .CLK_MHZ    ( clk_mhz )
    )
    i_vga
    (
        .clk        ( clk        ),
        .rst        ( rst        ),
        .hsync      ( hsync      ),
        .vsync      ( vsync      ),
        .display_on ( display_on ),
        .hpos       ( x          ),
        .vpos       ( y          )
    );

    //------------------------------------------------------------------------
    // Static pattern

    /*

    wire [19:0] x_2 = x ** 2;

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
            red   = 1;
            green = 0;
            blue  = 0;
        end
        else if ((x - 400) ** 2 + 2 * (y - 300) ** 2 < 100 ** 2)  // Ellipse
        begin
            red   = 0;
            green = 1;
            blue  = 0;
        end
        else if ((x_2 >> 9) < y)  // Parabola
        begin
            red   = 0;
            green = 0;
            blue  = 1;
        end
    end

    */

    //------------------------------------------------------------------------
    // Pattern 3 - dynamic

    /**/

    wire [9:0] dx = counter [27:18];
    wire [9:0] dy = counter [27:18];

    wire [19:0] x_2 = x ** 2;

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (~ display_on)
        begin
        end
        else if (x > 100 & (y - dy) > 100 & x < 150 & y < 400)  // Rectangle
        begin
            red   = 1;
            green = 0;
            blue  = 0;
        end
        else if ((x + dx - 400) ** 2 + 2 * (y - 300) ** 2 < 100 ** 2)  // Ellipse
        begin
            red   = 0;
            green = 1;
            blue  = 0;
        end
        else if (((((x + y) & 127) ** 2) >> 8) < ((y - dy) & 127))  // Parabola
        begin
            red   = counter [31] ^ x [6];
            green = counter [30] ^ y [7];
            blue  = counter [29];
        end
        else
        begin
            red   = 1;
            green = 1;
            blue  = 0;
        end
    end

    /**/

endmodule
