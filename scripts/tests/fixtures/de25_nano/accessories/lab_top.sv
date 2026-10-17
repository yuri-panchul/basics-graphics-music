`timescale 1 ns / 1 ps

// Lab-side stimulus and observation for the real board/peripheral RTL.
module lab_top
# (
    parameter clk_mhz = 50,
              w_key = 2, w_sw = 3, w_led = 8, w_digit = 8, w_gpio = 36,
              screen_width = 640, screen_height = 480,
              w_red = 8, w_green = 8, w_blue = 8,
              w_x = $clog2 (screen_width), w_y = $clog2 (screen_height)
)
(
    input clk, slow_clk, rst,
    input [w_key - 1:0] key,
    input [w_sw - 1:0] sw,
    output [w_led - 1:0] led,
    output [7:0] abcdefgh,
    output [w_digit - 1:0] digit,
    input [w_x - 1:0] x,
    input [w_y - 1:0] y,
    output [w_red - 1:0] red,
    output [w_green - 1:0] green,
    output [w_blue - 1:0] blue,
    input [23:0] mic,
    output [15:0] sound,
    input uart_rx,
    output uart_tx,
    inout [w_gpio - 1:0] gpio
);
    assign led = 8' (key);
    assign abcdefgh = tb.lab_segments;
    assign digit = tb.lab_digits;
    assign red = '0;
    assign green = '0;
    assign blue = '0;
    assign sound = tb.lab_sound;
    assign uart_tx = tb.lab_uart_tx;
    assign gpio [1] = tb.lab_gpio_out;
endmodule
