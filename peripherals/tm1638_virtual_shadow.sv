///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

`include "config.svh"
`include "lab_specific_board_config.svh"

module virtual_tm1638_shadow
# (
    parameter clk_mhz = 50,
              w_digit = 8,
    //`ifdef USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE
    //          w_keys = 16,
    //`else
              w_keys = 8,
    //`endif

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
    input        [           0:7] abcdefgh,
    input        [ w_digit - 1:0] digit,
    input        [           7:0] ledr,
    input        [ w_keys  - 1:0] keys,

    // graphics
    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue

);

`ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS
    localparam static_hex = 1'b0;
`else
    localparam static_hex = 1'b1;
`endif

    localparam w_seg   = 8;
    localparam dispx   = 4*w_digit+1;
    localparam dispy   = 7;
    localparam cellsx  = 8*w_digit+3;
    localparam cellsy  = 15;
    localparam clenx   = 8;  // screen_width / cellsx; // rounding low?
    localparam cleny   = 8;  // screen_height / cellsy;
    localparam offsetx = (screen_width - clenx*cellsx)/2;
    localparam offsety = (screen_height - cleny*cellsy)/2;

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
                'b00000001: r_hex0 <= abcdefgh;
                'b00000010: r_hex1 <= abcdefgh;
                'b00000100: r_hex2 <= abcdefgh;
                'b00001000: r_hex3 <= abcdefgh;
                'b00010000: r_hex4 <= abcdefgh;
                'b00100000: r_hex5 <= abcdefgh;
                'b01000000: r_hex6 <= abcdefgh;
                'b10000000: r_hex7 <= abcdefgh;
            endcase
        end
    end

    // HEX combinational
    wire [w_seg - 1:0] c_hex0,c_hex1,c_hex2,c_hex3,c_hex4,c_hex5,c_hex6,c_hex7;

    assign c_hex0 = digit [0] ? abcdefgh : '0;
    assign c_hex1 = digit [1] ? abcdefgh : '0;
    assign c_hex2 = digit [2] ? abcdefgh : '0;
    assign c_hex3 = digit [3] ? abcdefgh : '0;
    assign c_hex4 = digit [4] ? abcdefgh : '0;
    assign c_hex5 = digit [5] ? abcdefgh : '0;
    assign c_hex6 = digit [6] ? abcdefgh : '0;
    assign c_hex7 = digit [7] ? abcdefgh : '0;

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

    logic disp [dispy][dispx];
    wire a,b,c,d,e,f,g,h;
    assign a = abcdefgh[0];
    assign b = abcdefgh[1];
    assign c = abcdefgh[2];
    assign d = abcdefgh[3];
    assign e = abcdefgh[4];
    assign f = abcdefgh[5];
    assign g = abcdefgh[6];
    assign h = abcdefgh[7];

    genvar i;
    generate
        for (i = 0; i < w_keys; i++) begin : keys_display
            assign disp[dispy-1][i*4+0] = keys[i];
            assign disp[dispy-1][i*4+1] = keys[i];
            assign disp[dispy-1][i*4+2] = keys[i];
        end
        for (i = 0; i < $bits(ledr); i++) begin : leds_display
            assign disp[0][i*4+0] = ledr[i];
            assign disp[0][i*4+1] = ledr[i];
            assign disp[0][i*4+2] = ledr[i];
        end
        /*      '{0,0,0,0},
                '{0,0,a,0},
                '{0,f,0,b},
                '{0,0,g,0},
                '{0,e,0,c},
                '{0,0,d,0}};
        */
        for (i = 0; i < w_digit; i++) begin : segments_display
            assign disp[1][i*4+2] = a;
            assign disp[2][i*4+1] = f;
            assign disp[2][i*4+3] = b;
            assign disp[3][i*4+2] = g;
            assign disp[4][i*4+1] = e;
            assign disp[4][i*4+3] = c;
            assign disp[5][i*4+2] = d;
            assign disp[5][i*4+4] = h;
        end
    endgenerate

    logic [w_x-1:0] cx, dx; // cell and display x
    logic [w_y-1:0] cy, dy; // cell and display y
    logic dv;

    always_comb
    begin
        cx = (x-offsetx) / clenx;
        cy = (y-offsety) / cleny;
        dx = (cx>>2)+((cx+1)>>2); // 0123456789... => 000122234...
        dy = (cy>>2)+((cy+1)>>2);

        dv = (dx < dispx && dy < dispy)? disp[dy][dx] : 0;

        red   = dv ? 255:0;
        green = dv ? 255:0;
        blue  = dv ? 255:0;
    end

endmodule
