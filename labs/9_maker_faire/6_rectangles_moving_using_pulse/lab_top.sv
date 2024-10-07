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
       assign abcdefgh   = '0;
       assign digit      = '0;
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------
    //
    //  NOTE! Since the 9_maker_faire series of Verilog examples
    //  is for absolute beginners,
    //  we are using a simplified, more relaxed Verilog style
    //  that may have many lint issues. For example,
    //  we use "100" instead of "w_x' (100)" or "screen_width / 2".
    //
    //------------------------------------------------------------------------

    logic pulse;

    strobe_gen
    # (
        .clk_mhz   ( clk_mhz ),
        .strobe_hz ( 30      )
    )
    i_strobe_gen (clk, rst, pulse);

    //------------------------------------------------------------------------

    logic [7:0] counter;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            counter <= 0;
        else if (pulse)
            counter <= counter + 1;

    assign led = counter;

    //------------------------------------------------------------------------

    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;

        if (  x > 100 + counter
            & y > 100
            & x < 150 + counter
            & y < 200 )
        begin
            red = 30;
        end

        if (  x > 100 + counter * 2
            & y > 100 + counter
            & x < 150 + counter * 2
            & y < 200 + counter )
        begin
            green = 30;
        end
    end

endmodule
