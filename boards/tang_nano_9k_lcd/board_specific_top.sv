`include "config.svh"
`include "lab_specific_config.svh"

// `undef ENABLE_TM1638

module board_specific_top
# (
    parameter clk_mhz   = 27,
              pixel_mhz = 9,

              w_key     = 2,  // The last key is used for a reset
              w_sw      = 0,
              w_led     = 6,
              w_digit   = 0,
              w_gpio    = 10,

              w_red     = 5,
              w_green   = 6,
              w_blue    = 5
)
(
    input                        CLK,

    input  [w_key        - 1:0]  KEY,

    output [w_led        - 1:0]  LED,

    output                       LARGE_LCD_DE,
    output                       LARGE_LCD_VS,
    output                       LARGE_LCD_HS,
    output                       LARGE_LCD_CK,
    output                       LARGE_LCD_INIT,
    output                       LARGE_LCD_BL,

    output [7:7 + 1 - w_red   ]  LARGE_LCD_R,
    output [7:7 + 1 - w_green ]  LARGE_LCD_G,
    output [7:7 + 1 - w_blue  ]  LARGE_LCD_B,

    input                        UART_RX,
    output                       UART_TX,

    // The following 4 pins (TF_CS, TF_MOSI, TF_SCLK, TF_MISO)
    // are used for INMP441 microphone
    // in basics-graphics-music labs

    inout                        TF_CS,
    inout                        TF_MOSI,
    inout                        TF_SCLK,
    inout                        TF_MISO,

    inout  [w_gpio       - 1:0]  GPIO,

    // The 4 pins SMALL_LCD_CLK, _CS, _RS and _DATA
    // are used for the I2S audio output
    // in basics-graphics-music labs

    inout                        SMALL_LCD_CLK,
    inout                        SMALL_LCD_RESETN,
    inout                        SMALL_LCD_CS,
    inout                        SMALL_LCD_RS,
    inout                        SMALL_LCD_DATA,

    // TMDS pins will be used later

    // output                    TMDS_CLK_N,
    // output                    TMDS_CLK_P,
    // output [            2:0]  TMDS_D_N,
    // output [            2:0]  TMDS_D_P,

    output                       FLASH_CLK,
    output                       FLASH_CSB,
    output                       FLASH_MOSI,
    input                        FLASH_MISO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    =   8,
               w_tm_led    =   8,
               w_tm_digit  =   8;

    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        localparam w_top_key   = w_tm_key,
                   w_top_sw    = w_sw,
                   w_top_led   = w_tm_led,
                   w_top_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_top_key   = w_key,
                   w_top_sw    = w_sw,
                   w_top_led   = w_led,
                   w_top_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_top_key   - 1:0] top_key;
    wire  [w_top_led   - 1:0] top_led;
    wire  [w_top_digit - 1:0] top_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------


    `ifdef ENABLE_TM1638  // TM1638 module is connected

        assign rst      = tm_key [w_tm_key - 1];
        assign top_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = top_led;
        assign tm_digit = top_digit;

        assign LED      = w_led' (~ top_led);

    `else                 // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign top_key  = ~ KEY [w_key - 1:0];

        assign LED      = ~ top_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz    ( clk_mhz      ),
        .pixel_mhz  ( pixel_mhz    ),

        .w_key      ( w_top_key    ),  // The last key is used for a reset
        .w_sw       ( w_top_key    ),
        .w_led      ( w_top_led    ),
        .w_digit    ( w_top_digit  ),
        .w_gpio     ( w_gpio       ),

        .w_red      ( w_red        ),
        .w_green    ( w_green      ),
        .w_blue     ( w_blue       )
    )
    i_top
    (
        .clk        ( clk          ),
        .slow_clk   ( slow_clk     ),
        .rst        ( rst          ),

        .key        ( top_key      ),
        .sw         ( top_key      ),

        .led        ( top_led      ),

        .abcdefgh   ( abcdefgh     ),
        .digit      ( top_digit    ),

        .vsync      ( LARGE_LCD_VS ),
        .hsync      ( LARGE_LCD_HS ),

        .red        ( LARGE_LCD_R  ),
        .green      ( LARGE_LCD_G  ),
        .blue       ( LARGE_LCD_B  ),

        .display_on ( LARGE_LCD_DE ),
        .pixel_clk  ( LARGE_LCD_CK ),

        .uart_rx    ( UART_RX      ),
        .uart_tx    ( UART_TX      ),

        .mic        ( mic          ),
        .sound      ( sound        ),
        .gpio       ( gpio         )
    );

    assign LARGE_LCD_INIT = 1'b0;

    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    `endif

    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638

    tm1638_board_controller
    # (
        .clk_mhz  ( clk_mhz        ),
        .w_digit  ( w_tm_digit     )
    )
    i_tm1638
    (
        .clk      ( clk            ),
        .rst      ( rst            ),
        .hgfedcba ( hgfedcba       ),
        .digit    ( tm_digit       ),
        .ledr     ( tm_led         ),
        .keys     ( tm_key         ),
        .sio_data ( GPIO [0]       ),
        .sio_clk  ( GPIO [1]       ),
        .sio_stb  ( GPIO [2]       )
    );

    `endif

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk      ( clk            ),
        .rst      ( rst            ),
        .lr       ( TF_CS          ),
        .ws       ( TF_MOSI        ),
        .sck      ( TF_SCLK        ),
        .sd       ( TF_MISO        ),
        .value    ( mic            )
    );


    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz  ( clk_mhz        )
    )
    o_audio
    (
        .clk      ( clk            ),
        .reset    ( rst            ),
        .data_in  ( sound          ),
        .mclk     ( SMALL_LCD_DATA ),
        .bclk     ( SMALL_LCD_CLK  ),
        .lrclk    ( SMALL_LCD_RS   ),
        .sdata    ( SMALL_LCD_CS   )
    );

endmodule
