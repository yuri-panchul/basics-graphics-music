module board_specific_top
# (
    parameter clk_mhz = 100,
              w_key   = 5,
              w_sw    = 16,
              w_led   = 16,
              w_digit = 8,
              w_gpio  = 32
)
(
    input         CLK100MHZ,
    input         CPU_RESETN,

    input         BTNC,
    input         BTNU,
    input         BTNL,
    input         BTNR,
    input         BTND,

    input  [15:0] SW,
    output [15:0] LED,

    output        LED16_B,
    output        LED16_G,
    output        LED16_R,

    output        LED17_B,
    output        LED17_G,
    output        LED17_R,

    output        CA,
    output        CB,
    output        CC,
    output        CD,
    output        CE,
    output        CF,
    output        CG,

    output        DP,

    output [ 7:0] AN,

    output [ 3:0] VGA_R,
    output [ 3:0] VGA_G,
    output [ 3:0] VGA_B,

    output        VGA_HS,
    output        VGA_VS,

    input         UART_TXD_IN,

    inout  [12:1] JA,
    inout  [12:1] JB,
    inout  [12:1] JC,
    inout  [12:1] JD,

    output        M_CLK,
    input         M_DATA,
    output        M_LRSEL,

    output        AUD_PWM,
    output        AUD_SD
);

    //------------------------------------------------------------------------

    wire clk =   CLK100MHZ;
    wire rst = ~ CPU_RESETN;

    //------------------------------------------------------------------------

    assign LED16_B = 1'b0;
    assign LED16_G = 1'b0;
    assign LED16_R = 1'b0;
    assign LED17_B = 1'b0;
    assign LED17_G = 1'b0;
    assign LED17_R = 1'b0;

    assign M_CLK   = 1'b0;
    assign M_LRSEL = 1'b0;

    assign AUD_PWM = 1'b0;
    assign AUD_SD  = 1'b0;

    //------------------------------------------------------------------------

    wire [ 7:0] abcdefgh;
    wire [ 7:0] digit;

    assign { CA, CB, CC, CD, CE, CF, CG, DP } = ~ abcdefgh;
    assign AN = ~ digit;

    wire [23:0] mic = '0;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk      ( clk      ),
        .rst      ( rst      ),

        .key      ( { BTND, BTNU, BTNL, BTNC, BTNR } ),
        .sw       ( SW       ),

        .led      ( LED      ),

        .abcdefgh ( abcdefgh ),

        .digit    ( digit    ),

        .vsync    ( VGA_VS   ),
        .hsync    ( VGA_HS   ),

        .red      ( VGA_R    ),
        .green    ( VGA_G    ),
        .blue     ( VGA_B    ),

        .mic      ( mic      ),
        .gpio     (          )
    );

endmodule
