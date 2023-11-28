`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 100,
              w_key   = 5,
              w_sw    = 16,
              w_led   = 16,
              w_digit = 4,
              w_gpio  = 24
)
(
    input         clk,

    input         btnC,
    input         btnU,
    input         btnL,
    input         btnR,
    input         btnD,

    input  [15:0] sw,
    output [15:0] led,

    output [ 6:0] seg,
    output        dp,
    output [ 3:0] an,

    output        Hsync,
    output        Vsync,

    output [ 3:0] vgaRed,
    output [ 3:0] vgaBlue,
    output [ 3:0] vgaGreen,

    input         RsRx,

    inout  [ 7:0] JA,
    inout  [ 7:0] JB,
    inout  [ 7:0] JC
);

    //------------------------------------------------------------------------

    localparam w_top_sw   = w_sw - 1;  // One onboard SW is used as a reset

    wire                  rst    = sw [w_sw - 1];
    wire [w_top_sw - 1:0] top_sw = sw [w_top_sw - 1:0];

    // FIXME: Should be assigned to some GPIO!
    wire                  UART_RX = '1;
    wire                  UART_TX;

    //------------------------------------------------------------------------

    wire [7:0] abcdefgh;
    wire [7:0] digit;

    assign { seg [0], seg [1], seg [2], seg [3],
             seg [4], seg [5], seg [6], dp       } = ~ abcdefgh;

    assign an = ~ digit;

    wire        mic_ready;
    wire [23:0] mic;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz  ),
        .w_key   ( w_key    ),
        .w_sw    ( w_top_sw ),
        .w_led   ( w_led    ),
        .w_digit ( w_digit  ),
        .w_gpio  ( w_gpio   )
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

        .mic      ( mic         ),
        .mic_ready( mic_ready   ),
        .gpio     (             )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (.clk_mhz (100))
    i_microphone
    (
        .clk   ( clk    ),
        .rst   ( rst    ),
        .lr    ( JA [6] ),
        .ws    ( JA [5] ),
        .sck   ( JA [4] ),
        .sd    ( JA [0] ),
        .ready ( mic_ready ),
        .value ( mic       )
    );

    assign JA [2] = 1'b0;  // GND - JA pin 3
    assign JA [1] = 1'b1;  // VCC - JA pin 2

endmodule
