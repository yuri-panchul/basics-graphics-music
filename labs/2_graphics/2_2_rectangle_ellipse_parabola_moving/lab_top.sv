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
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire enable;

    // Generate a strobe signal 10 times a second

    strobe_gen
    # (.clk_mhz (clk_mhz), .strobe_hz (30))
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

    wire [w_x * 2 - 1:0] x_2 = x * x;

    // These additional wires are needed
    // because some graphics interfaces have up to 10 bits per color channel

    wire [10:0] x11 = 11' (x);
    wire [ 9:0] y10 = 10' (y);

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (   x + dx >= screen_width  / 2
             & x + dx <  screen_width  * 2 / 3
             & y      >= screen_height / 2
             & y      <  screen_height * 2 / 3 )
        begin
            if (key [0])
                green = '1;
            else
                green = x11 [$left (x11) - 1 -: w_green];
        end

        `ifdef YOSYS
        if (x * x  + 2 * y * y  < (screen_width + dx) * (screen_width + dy) / 4)  // Ellipse
        `else
        if (x ** 2 + 2 * y ** 2 < (screen_width / 2 + dx) ** 2)  // Ellipse
        `endif
        begin
            red = x11 [$left (x11) - 1 -: w_red];
        end

        if (x_2 [w_x +: w_y] < y + dy)  // Parabola
            blue = key [1] ? '1 : y10 [$left (y10) -: w_blue];
    end

endmodule
