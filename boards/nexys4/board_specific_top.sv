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
    input         clk,
    input         btnCpuReset,

    input         btnC,
    input         btnU,
    input         btnL,
    input         btnR,
    input         btnD,

    input  [15:0] sw,
    output [15:0] led,

    output        RGB1_Red,
    output        RGB1_Green,
    output        RGB1_Blue,

    output        RGB2_Red,
    output        RGB2_Green,
    output        RGB2_Blue,

    output [ 6:0] seg,
    output        dp,
    output [ 7:0] an,

    output        Hsync,
    output        Vsync,

    output [ 3:0] vgaRed,
    output [ 3:0] vgaBlue,
    output [ 3:0] vgaGreen,

    input         RsRx,

    inout  [ 7:0] JA,
    inout  [ 7:0] JB,
    inout  [ 7:0] JC,
    inout  [ 7:0] JD,

    output        micClk,
    input         micData,
    output        micLRSel,

    output        ampPWM,
    output        ampSD
);

    //------------------------------------------------------------------------

    wire rst = ~ btnCpuReset;

    //------------------------------------------------------------------------

    assign RGB1_Red   = 1'b0;
    assign RGB1_Green = 1'b0;
    assign RGB1_Blue  = 1'b0;

    assign RGB2_Red   = 1'b0;
    assign RGB2_Green = 1'b0;
    assign RGB2_Blue  = 1'b0;

    assign micClk     = 1'b0;
    assign micLRSel   = 1'b0;

    assign ampPWM     = 1'b0;
    assign ampSD      = 1'b0;

    //------------------------------------------------------------------------

    wire [ 7:0] abcdefgh;
    wire [ 7:0] digit;

    assign { seg, dp } = ~ abcdefgh;
    assign an          = ~ digit;

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
        .clk      ( clk         ),
        .rst      ( rst         ),

        .key      ( { btnU, btnD, btnL, btnC, btnR } ),
        .sw       ( sw          ),

        .led      ( led         ),

        .abcdefgh ( abcdefgh    ),

        .digit    ( digit       ),

        .vsync    ( Vsync       ),
        .hsync    ( Hsync       ),

        .red      ( vgaRed      ),
        .green    ( vgaBlue     ),
        .blue     ( vgaGreen    ),

        .mic      ( mic         ),
        .gpio     (             )
    );

endmodule
