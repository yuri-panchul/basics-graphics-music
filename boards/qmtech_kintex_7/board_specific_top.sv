`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 50

)
(
    input         CLK_IN,
    input         RST_IN,
    //
    input         BTN_A,
    input         BTN_B,
    input         BTN_C,
    input         BTN_D,
    input         BTN_E,
    //
    output        AN,
    output        BN,
    output        CN,
    output        DN,
    //
    output        CA,
    output        CB,
    output        CC,
    output        CD,
    output        CE,
    output        CF,
    output        CG,
    output        DP,
    //
    output        LED_OUT_A,
    output        LED_OUT_B,
    output        LED_OUT_C,
    output        LED_OUT_D,
    output        LED_OUT_E,
    output        LED_OUT_F

);

    //------------------------------------------------------------------------

    wire clk =   CLK_IN;
    wire rst = ~ RST_IN;

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
    wire [ 3:0] digit;

    assign { DP, CG, CF, CE, CD, CC, CB, CA } = abcdefgh;
    assign { DN, CN, BN, AN } = ~ digit;

    wire [23:0] mic = '0;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( 5 ),
        .w_sw    ( 0 ),
        .w_led   ( 6 ),
        .w_digit ( 4 ),
        .w_gpio  ( 0 )
    )
    i_lab_top
    (
        .clk      ( clk      ),
        .slow_clk ( slow_clk ),
        .rst      ( rst      ),

        .key      ( {~ BTN_E, BTN_D, BTN_C, BTN_B, BTN_A} ),
        .sw       ( '0 ),

        .led      ( {LED_OUT_F, LED_OUT_E, LED_OUT_D, LED_OUT_C, LED_OUT_B, LED_OUT_A} ),

        .abcdefgh ( abcdefgh ),

        .digit    ( digit    ),

        .vsync    ( '0 ),
        .hsync    ( '0 ),

        .red      ( ),
        .green    ( ),
        .blue     ( ),

        .mic      ( '0 ),
        .gpio     (   )
    );

endmodule
