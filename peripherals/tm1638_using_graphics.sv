///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

`include "config.svh"
`include "lab_specific_board_config.svh"

module virtual_tm1638_using_graphics
# (
    parameter w_digit = 8,
              w_keys = 8,

              screen_width  = 640,
              screen_height = 480,

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
    input        [ w_keys  - 1:0] keys,

    // graphics
    input        [w_x     - 1:0]  x,
    input        [w_y     - 1:0]  y,

    output logic                  red,
    output logic                  green,
    output logic                  blue

);

    localparam w_seg   = 8;
    localparam dispx   = 4*w_digit+1;
    localparam dispy   = 8;  // 4 lines: leds, keys, separator, segments (5)
    localparam cellsx  = 8*w_digit+3;
    localparam cellsy  = 16; // separator is for alignment and display power-on indication
    localparam clenx_s = $clog2(screen_width / cellsx)-1;
    localparam cleny_s = clenx_s;
    localparam offsetx = (screen_width  - (1<<clenx_s)*cellsx)/2;
    localparam offsety = (screen_height - (1<<cleny_s)*cellsy)/2;

    wire [w_seg - 1:0] hex[w_digit];

    tm1638_registers
    # (
        .w_digit  ( w_digit ),
        .r_init   (   // hgfedcba             --a--
                    '{8'b00111111, // 0      |     |
                      8'b00000110, // 1      f     b
                      8'b01011011, // 2      |     |
                      8'b01001111, // 3       --g--
                      8'b01100110, // 4      |     |
                      8'b01101101, // 5      e     c
                      8'b01111101, // 6      |     |
                      8'b00000111})// 7       --d--
    )
    i_tm1638_regs
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .hgfedcba ( hgfedcba ),
        .digit    ( digit    ),
        .hex      ( hex      )
    );

    wire disp [dispx][dispy];

    genvar i;
    generate
        for (i = 0; i < $bits(ledr); i++) begin : leds_display
            assign disp[(w_digit-1-i)*4+1][0] = ledr[i];
            assign disp[(w_digit-1-i)*4+2][0] = ledr[i];
            assign disp[(w_digit-1-i)*4+3][0] = ledr[i];
        end
        for (i = 1; i < dispx-1; i++) begin : separator_display
            assign disp[i][1] = '1;
        end
        for (i = 0; i < w_keys; i++) begin : keys_display
            assign disp[(w_digit-1-i)*4+1][2] = keys[i];
            assign disp[(w_digit-1-i)*4+2][2] = keys[i];
            assign disp[(w_digit-1-i)*4+3][2] = keys[i];
        end
        for (i = 0; i < w_digit; i++) begin : segments_display
            assign disp[(w_digit-1-i)*4+2][3] = hex[i][0]; // a     '{0,0,0,0},
            assign disp[(w_digit-1-i)*4+1][4] = hex[i][5]; // f     '{0,0,a,0},
            assign disp[(w_digit-1-i)*4+3][4] = hex[i][1]; // b     '{0,f,0,b},
            assign disp[(w_digit-1-i)*4+2][5] = hex[i][6]; // g     '{0,0,g,0},
            assign disp[(w_digit-1-i)*4+1][6] = hex[i][4]; // e     '{0,e,0,c},
            assign disp[(w_digit-1-i)*4+3][6] = hex[i][2]; // c     '{0,0,d,0,h}};
            assign disp[(w_digit-1-i)*4+2][7] = hex[i][3]; // d
            assign disp[(w_digit-1-i)*4+4][7] = hex[i][7]; // h
        end
    endgenerate

    logic [w_x-1:0] cx, dx; // cell and display x
    logic [w_y-1:0] cy, dy; // cell and display y

    always_comb
    begin
        cx = (x-offsetx) >> clenx_s;
        cy = (y-offsety) >> cleny_s;
        dx = (cx>>2)+((cx+1)>>2); // 0123456789ABC... => 000122234445...
        dy = (cy>>2)+((cy+1)>>2);

        red   = (dx < dispx && dy < dispy)? disp[dx][dy] : 0;
        green = dy==2 ? '0 : red;
        blue  = dy==0 ? '0 : red;
    end

endmodule
