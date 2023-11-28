`include "config.svh"
`include "lab_specific_config.svh"

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

    wire [7:0] abcdefgh;
    wire [7:0] digit;

    assign { seg [0], seg [1], seg [2], seg [3],
             seg [4], seg [5], seg [6], dp       } = ~ abcdefgh;

    assign an = ~ digit;

    wire [23:0] mic;
    wire        mic_ready;

    // FIXME: Should be assigned to some GPIO!
    wire        UART_TX;
    wire        UART_RX = '1;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

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
        .slow_clk ( slow_clk    ),
        .rst      ( rst         ),

        .key      ( { btnD, btnU, btnL, btnC, btnR } ),
        .sw       ( sw          ),

        .led      ( led         ),

        .abcdefgh ( abcdefgh    ),

        .digit    ( digit       ),

        .vsync    ( Vsync       ),
        .hsync    ( Hsync       ),

        .red      ( vgaRed      ),
        .green    ( vgaBlue     ),
        .blue     ( vgaGreen    ),

        .uart_rx  ( UART_RX     ),
        .uart_tx  ( UART_TX     ),

        .mic_ready( mic_ready   ),
        .mic      ( mic         ),
        .gpio     (             )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (.clk_mhz (100))
    i_microphone
    (
        .clk   ( clk    ),
        .rst   ( rst    ),
        .lr    ( JD [6] ),
        .ws    ( JD [5] ),
        .sck   ( JD [4] ),
        .sd    ( JD [0] ),
        .ready ( mic_ready),
        .value ( mic    )
    );

    assign JD [2] = 1'b0;  // GND - JD pin 3
    assign JD [1] = 1'b1;  // VCC - JD pin 2

endmodule
