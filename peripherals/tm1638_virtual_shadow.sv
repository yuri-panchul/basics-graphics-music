///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

`include "config.svh"
`include "lab_specific_board_config.svh"

module virtual_tm1638_shadow
# (
    parameter clk_mhz = 50,
              w_digit = 8,
              w_keys = 8,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                         clk,
    input                         rst,

    // tm1638 inputs
    input        [           7:0] abcdefgh,
    input        [ w_digit - 1:0] digit,
    input        [           7:0] ledr,
    input        [ w_keys  - 1:0] keys,

    // graphics
    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic inv_red,
    output logic inv_green,
    output logic inv_blue

);

`ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS
    localparam static_hex = 1'b0;
`else
    localparam static_hex = 1'b1;
`endif

    localparam w_seg   = 8;
    localparam dispx   = 4*w_digit+1;
    localparam dispy   = 8;  // 4 lines: leds, segments (5), keys, reserved for alignment
    localparam cellsx  = 8*w_digit+3;
    localparam cellsy  = 16;
    localparam clenx   = 8;  // screen_width / cellsx;
    localparam cleny   = clenx;
    localparam offsetx = (screen_width - clenx*cellsx)/2;
    localparam offsety = (screen_height - cleny*cellsy)/2;

    ////////////// TM1563 data /////////////////
    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h

    // HEX registered
    logic [w_seg - 1:0] r_hex[w_digit];

    always @( posedge clk )
    begin
        if (rst) begin   //abcdefgh
            r_hex[0] <= 8'b11111100; // 0
            r_hex[1] <= 8'b01100000; // 1
            r_hex[2] <= 8'b11011010; // 2
            r_hex[3] <= 8'b11110010; // 3
            r_hex[4] <= 8'b01100110; // 4
            r_hex[5] <= 8'b10110110; // 5
            r_hex[6] <= 8'b10111110; // 6
            r_hex[7] <= 8'b11100000; // 7
        end
        else
        begin
            case (digit)
                'b00000001: r_hex[0] <= abcdefgh;
                'b00000010: r_hex[1] <= abcdefgh;
                'b00000100: r_hex[2] <= abcdefgh;
                'b00001000: r_hex[3] <= abcdefgh;
                'b00010000: r_hex[4] <= abcdefgh;
                'b00100000: r_hex[5] <= abcdefgh;
                'b01000000: r_hex[6] <= abcdefgh;
                'b10000000: r_hex[7] <= abcdefgh;
            endcase
        end
    end

    // HEX combinational
    wire [w_seg - 1:0] c_hex[w_digit];

    assign c_hex[0] = digit [0] ? abcdefgh : '0;
    assign c_hex[1] = digit [1] ? abcdefgh : '0;
    assign c_hex[2] = digit [2] ? abcdefgh : '0;
    assign c_hex[3] = digit [3] ? abcdefgh : '0;
    assign c_hex[4] = digit [4] ? abcdefgh : '0;
    assign c_hex[5] = digit [5] ? abcdefgh : '0;
    assign c_hex[6] = digit [6] ? abcdefgh : '0;
    assign c_hex[7] = digit [7] ? abcdefgh : '0;

    // Select combinational or registered HEX (blink or not)
    wire [w_seg - 1:0] hex[w_digit];

    assign hex[0] = static_hex ? r_hex[0] : c_hex[0];
    assign hex[1] = static_hex ? r_hex[1] : c_hex[1];
    assign hex[2] = static_hex ? r_hex[2] : c_hex[2];
    assign hex[3] = static_hex ? r_hex[3] : c_hex[3];
    assign hex[4] = static_hex ? r_hex[4] : c_hex[4];
    assign hex[5] = static_hex ? r_hex[5] : c_hex[5];
    assign hex[6] = static_hex ? r_hex[6] : c_hex[6];
    assign hex[7] = static_hex ? r_hex[7] : c_hex[7];

    wire disp [dispx][dispy];

    genvar i, k;
    generate
        for (i = 0; i < w_keys; i++) begin : keys_display
            assign disp[i*4+1][dispy-2] = keys[i];
            assign disp[i*4+2][dispy-2] = keys[i];
            assign disp[i*4+3][dispy-2] = keys[i];
        end
        for (i = 0; i < $bits(ledr); i++) begin : leds_display
            assign disp[i*4+1][0] = ledr[i];
            assign disp[i*4+2][0] = ledr[i];
            assign disp[i*4+3][0] = ledr[i];
        end
        for (i = 0; i < w_digit; i++) begin : segments_display
            assign disp[i*4+2][1] = hex[i][7]; // a     '{0,0,0,0},
            assign disp[i*4+1][2] = hex[i][2]; // f     '{0,0,a,0},
            assign disp[i*4+3][2] = hex[i][6]; // b     '{0,f,0,b},
            assign disp[i*4+2][3] = hex[i][1]; // g     '{0,0,g,0},
            assign disp[i*4+1][4] = hex[i][3]; // e     '{0,e,0,c},
            assign disp[i*4+3][4] = hex[i][5]; // c     '{0,0,d,0,h}};
            assign disp[i*4+2][5] = hex[i][4]; // d
            assign disp[i*4+4][5] = hex[i][0]; // h
        end
        for (i = 1; i < dispx-1; i++) begin : underline_display
            assign disp[i][dispy-1] = '1;
        end
    endgenerate

    logic [w_x-1:0] cx, dx; // cell and display x
    logic [w_y-1:0] cy, dy; // cell and display y

    always_comb
    begin
        cx = (x-offsetx) / clenx;
        cy = (y-offsety) / cleny;
        dx = (cx>>2)+((cx+1)>>2); // 0123456789ABC... => 000122234445...
        dy = (cy>>2)+((cy+1)>>2);

        inv_red   = (dx < dispx && dy < dispy)? disp[dx][dy] : 0;
        inv_green = dy==dispy-2 ? '0 : inv_red;
        inv_blue  = dy==0 ? '0 : inv_red;
    end

endmodule
