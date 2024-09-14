`include "config.svh"
`include "lab_specific_board_config.svh"

//----------------------------------------------------------------------------

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

`define IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 25,

              w_key         = 2,  // The last key is used for a reset
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 5,

              screen_width  = 800,
              screen_height = 480,

              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        CLK,

    input  [w_key        - 1:0]  KEY,

    output [w_led        - 1:0]  LED,

    // Some LCD pins share bank with TMDS pins
    // which have different voltage requirements.
    //
    // However we can use LCD_DE, VS, HS, CK,
    // because they are assigned to a different bank.

    output                       LCD_DE,
    output                       LCD_VS,
    output                       LCD_HS,
    output                       LCD_CK,
    output                       LCD_BL,
    output                       LCD_INIT,

    output [7:7 + 1 - w_red   ]  LCD_R,
    output [7:7 + 1 - w_green ]  LCD_G,
    output [7:7 + 1 - w_blue  ]  LCD_B,

    input                        UART_RX,
    output                       UART_TX,

    // The following 4 pins (MIC_LR, MIC_WS, MIC_SCLK, MIC_SD)
    // are used for INMP441 microphone
    // in basics-graphics-music labs

    inout                        MIC_LR,
    inout                        MIC_WS,
    inout                        MIC_SCLK,
    inout                        MIC_SD,

    inout  [w_gpio       - 1:0]  GPIO,

    // TMDS pins conflict with LCD pins

    // output                       TMDS_CLK_N,
    // output                       TMDS_CLK_P,
    // output [               2:0]  TMDS_D_N,
    // output [               2:0]  TMDS_D_P,

    // Pins for onboard I2S DAC
    output                       I2S_BCLK,
    output                       I2S_LRCK,
    output                       I2S_DIN,
    output                       I2S_EN
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_lab_key   = w_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_led,
                   w_lab_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] red;
    wire  [w_green     - 1:0] green;
    wire  [w_blue      - 1:0] blue;

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (~ lab_led);

    `elsif IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

        wire rst;

        imitate_reset_on_power_up i_imitate_reset_on_power_up (clk, rst);

        assign lab_key  = ~ KEY [w_key - 1:0];
        assign LED      = ~ lab_led;

    `else  // TM1638 module is not connected and no reset initation

        assign rst      = ~ KEY [w_key - 1];
        assign lab_key  = ~ KEY [w_key - 1:0];

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    wire  [w_x - 1:0] mirrored_x = w_x' (screen_width  - 1 - x);
    wire  [w_y - 1:0] mirrored_y = w_y' (screen_height - 1 - y);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_lab_key     ),  // The last key is used for a reset
        .w_sw          ( w_lab_key     ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_key       ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( mirrored_x    ),
        .y             ( mirrored_y    ),

        .red           ( LCD_R         ),
        .green         ( LCD_G         ),
        .blue          ( LCD_B         ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          ( gpio          )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

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

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

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


    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire lcd_module_clk;

        Gowin_rPLL i_Gowin_rPLL
        (
            .clkout  ( lcd_module_clk ),  // 200    MHz
            .clkoutd ( LCD_CLK        ),  //  33.33 MHz
            .clkin   ( clk            )   //  27    MHz
        );

        lcd_800_480 i_lcd
        (
            .CLK       (   lcd_module_clk ),

            .PixelClk  (   LCD_CK         ),
            .nRST      ( ~ rst            ),

            .LCD_DE    (   LCD_DE         ),
            .LCD_HSYNC (   LCD_HS         ),
            .LCD_VSYNC (   LCD_VS         ),

            .x         (   x              ),
            .y         (   y              )
        );

        assign LCD_INIT = 1'b0;
        assign LCD_BL   = 1'b0;

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz  ( clk_mhz        )
        )
        i_microphone
        (
            .clk      ( clk            ),
            .rst      ( rst            ),
            .lr       ( MIC_LR         ),
            .ws       ( MIC_WS         ),
            .sck      ( MIC_SCLK       ),
            .sd       ( MIC_SD         ),
            .value    ( mic            )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        // For tang_nano_20k DAC do not require mclk signal
        // but it needs enable signal I2S_EN

        i2s_audio_out
        # (
            .clk_mhz  ( clk_mhz      )
        )
        inst_audio_out
        (
            .clk      ( clk          ),
            .reset    ( rst          ),
            .data_in  ( sound        ),
            .mclk     (              ),
            .bclk     ( I2S_BCLK     ),
            .lrclk    ( I2S_LRCK     ),
            .sdata    ( I2S_DIN      )
        );

        // Enable DAC
        assign I2S_EN = 1'b1;

    `endif

endmodule
