///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

`include "config.svh"
`include "lab_specific_board_config.svh"

module virtual_tm1638_shadow
# (
    parameter clk_mhz = 50,
              w_digit = 8,
              w_seg   = 8,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                         clk,
    input                         rst,

    // tm1638 inputs
    input        [           7:0] hgfedcba,
    input        [ w_digit - 1:0] digit,
    input        [           7:0] ledr,
    input logic  [          15:0] keys,

    // graphics
    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue

);

    logic  [7:0] led_on;

    logic        tm_rw;
    wire         dio_in, dio_out;

    `ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS
        localparam static_hex = 1'b0;
    `else
        localparam static_hex = 1'b1;
    `endif

    ////////////// TM1563 data /////////////////

    // HEX registered
    logic [w_seg - 1:0] r_hex0,r_hex1,r_hex2,r_hex3,r_hex4,r_hex5,r_hex6,r_hex7;

    always @( posedge clk )
    begin
        if (rst) begin
            r_hex0 <= 'b0;
            r_hex1 <= 'b0;
            r_hex2 <= 'b0;
            r_hex3 <= 'b0;
            r_hex4 <= 'b0;
            r_hex5 <= 'b0;
            r_hex6 <= 'b0;
            r_hex7 <= 'b0;
        end
        else
        begin
            case (digit)
                'b00000001: r_hex0 <= hgfedcba;
                'b00000010: r_hex1 <= hgfedcba;
                'b00000100: r_hex2 <= hgfedcba;
                'b00001000: r_hex3 <= hgfedcba;
                'b00010000: r_hex4 <= hgfedcba;
                'b00100000: r_hex5 <= hgfedcba;
                'b01000000: r_hex6 <= hgfedcba;
                'b10000000: r_hex7 <= hgfedcba;
            endcase
        end
    end

    // HEX combinational
    wire [w_seg - 1:0] c_hex0,c_hex1,c_hex2,c_hex3,c_hex4,c_hex5,c_hex6,c_hex7;

    assign c_hex0 = digit [0] ? hgfedcba : '0;
    assign c_hex1 = digit [1] ? hgfedcba : '0;
    assign c_hex2 = digit [2] ? hgfedcba : '0;
    assign c_hex3 = digit [3] ? hgfedcba : '0;
    assign c_hex4 = digit [4] ? hgfedcba : '0;
    assign c_hex5 = digit [5] ? hgfedcba : '0;
    assign c_hex6 = digit [6] ? hgfedcba : '0;
    assign c_hex7 = digit [7] ? hgfedcba : '0;

    // Select combinational or registered HEX (blink or not)
    wire [w_seg - 1:0] hex0,hex1,hex2,hex3,hex4,hex5,hex6,hex7;

    assign hex0 = static_hex ? r_hex0 : c_hex0;
    assign hex1 = static_hex ? r_hex1 : c_hex1;
    assign hex2 = static_hex ? r_hex2 : c_hex2;
    assign hex3 = static_hex ? r_hex3 : c_hex3;
    assign hex4 = static_hex ? r_hex4 : c_hex4;
    assign hex5 = static_hex ? r_hex5 : c_hex5;
    assign hex6 = static_hex ? r_hex6 : c_hex6;
    assign hex7 = static_hex ? r_hex7 : c_hex7;

    wire [10:0] x11 = 11' (x);
    wire [ 9:0] y10 = 10' (y);

    always_comb
    begin
        red   = '0;
        green = '0;
        blue  = '0;

        if (   x >= screen_width  / 2
             & x <  screen_width  * 2 / 3
             & y >= screen_height / 2
             & y <  screen_height * 2 / 3 )
        begin
            if (keys [0])
                green = '1;
            else
                green = x11 [$left (x11) - 1 -: w_green];
        end

        red = x11 [$left (x11) - 1 -: w_red];

        blue = keys[1] ? '1 : y10 [$left (y10) -: w_blue];
    end

endmodule
