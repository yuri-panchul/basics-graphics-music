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

       assign led      = '0;
       assign abcdefgh = '0;
       assign digit    = '0;
    // assign vsync    = '0;
    // assign hsync    = '0;
    // assign red      = '0;
    // assign green    = '0;
    // assign blue     = '0;

    //------------------------------------------------------------------------

    localparam w_x = 10, w_y = 10;

    //------------------------------------------------------------------------

    wire display_on;

    wire [w_x - 1:0] x;
    wire [w_y - 1:0] y;

    vga
    # (
        .HPOS_WIDTH ( w_x     ),
        .VPOS_WIDTH ( w_y     ),

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
    // Pattern 1

    /**/

    wire [w_x * 2 - 1:0] x_2 = x ** 2;

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
            red   = x [w_x - 2 -: 4];
            green = '1;
            blue  = y [w_y - 2 -: 4];
        end
        else if ((x - 400) ** 2 + 2 * (y - 300) ** 2 < 100 ** 2)  // Ellipse
        begin
            red   = '1;
            green = x [w_x - 2 -: 4];
            blue  = y [w_y - 2 -: 4];
        end
        else if (x_2 [9 +: w_y] < y)  // Parabola
        begin
            red   = x [w_x - 2 -: 4];
            green = y [w_y - 2 -: 4];
            blue  = '1;
        end
    end

    /**/

    //------------------------------------------------------------------------
    // Pattern 3 - dynamic

    /*

    wire enable;

    // Generate a strobe signal 10 times a second

    strobe_gen
    # (.clk_mhz (clk_mhz), .strobe_hz (10))
    i_strobe_gen
    (.strobe (enable), .*);

    //------------------------------------------------------------------------

    wire inv_key_0 = ~ key [0];
    wire inv_key_1 = ~ key [1];

    logic [7:0] dx, dy;

    always_ff @ (posedge clk)
        if (rst)
        begin
            dx <= 4'b0;
            dy <= 4'b0;
        end
        else if (enable)
        begin
            dx <= dx + inv_key_0;
            dy <= dy + inv_key_1;
        end

    //------------------------------------------------------------------------

    wire [3:0] xc = x [w_x - 2 -: 4];
    wire [3:0] yc = y [w_y - 2 -: 4];

    always_comb
    begin
      red   = '0;
      green = '0;
      blue  = '0;

      if (display_on)
      begin
        red   = xc + xc + yc + dx;
        green = xc - yc - dy;
        blue  = { 4 { & key } };
      end
    end

    */

endmodule
