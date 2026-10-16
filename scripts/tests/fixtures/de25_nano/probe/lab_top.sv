`timescale 1 ns / 1 ps

// A lab-side contract probe: real teaching labs are exercised separately.
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
    assign led = { rst, sw, key, 1'b0, gpio [0] };
    assign gpio [1] = key [0];
    assign abcdefgh = '0;
    assign digit = '0;
    assign red = 8'h12;
    assign green = 8'h34;
    assign blue = 8'h56;
    assign sound = '0;
    assign uart_tx = '1;

    initial
    begin
        #1;
        if (w_key != 2 || w_sw != 3 || w_led != 8 || w_digit < 2 || w_gpio != 36)
            $fatal (1, "Invalid lab interface widths");
        if (mic !== 24'b0 || uart_rx !== 1'b1)
            $fatal (1, "Absent peripherals must have defined inactive inputs");
        `ifndef DE25_TEST_VIDEO
            if (x !== '0 || y !== '0)
                $fatal (1, "Disabled graphics must provide zero coordinates");
        `endif
    end
endmodule
