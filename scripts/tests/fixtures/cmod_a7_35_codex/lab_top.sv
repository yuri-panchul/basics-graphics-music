module lab_top
# (
    parameter clk_mhz=100, w_key=8, w_sw=8, w_led=8, w_digit=8, w_gpio=8,
              screen_width=640, screen_height=480, w_red=2, w_green=2, w_blue=2,
              w_x=$clog2(screen_width), w_y=$clog2(screen_height)
)
(
    input clk, slow_clk, rst,
    input [w_key-1:0] key,
    input [w_sw-1:0] sw,
    output [w_led-1:0] led,
    output [7:0] abcdefgh,
    output [w_digit-1:0] digit,
    input [w_x-1:0] x,
    input [w_y-1:0] y,
    output [w_red-1:0] red,
    output [w_green-1:0] green,
    output [w_blue-1:0] blue,
    input [23:0] mic,
    output [15:0] sound,
    input uart_rx,
    output uart_tx,
    inout [w_gpio-1:0] gpio
);
    assign led = w_led'(key);
    assign abcdefgh = 8'h80;
    assign digit = 1;
    assign red = 2'b10;
    assign green = 2'b01;
    assign blue = 2'b11;
    assign sound = 16'h5a3c;
    assign uart_tx = uart_rx;
    assign gpio = 8'ha6;
endmodule
