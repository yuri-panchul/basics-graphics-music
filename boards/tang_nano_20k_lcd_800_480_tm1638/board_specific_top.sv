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
    output                       LCD_CLK,

    output [            4:0]     LCD_R,
    output [            5:0]     LCD_G,
    output [            4:0]     LCD_B,

    input                        UART_RX,
    output                       UART_TX,

    inout  [w_gpio       - 1:0]  GPIO,

    // DVI ports
    // output                    O_TMDS_CLK_N,
    // output                    O_TMDS_CLK_P,
    // output [            2:0]  O_TMDS_DATA_N,
    // output [            2:0]  O_TMDS_DATA_P,

    inout                        EDID_CLK,
    inout                        EDID_DAT,

    // output                    JOYSTICK_CLK,
    // output                    JOYSTICK_MOSI,
    // output                    JOYSTICK_MISO,
    // output                    JOYSTICK_CS,

    // output                    JOYSTICK_CLK2,
    // output                    JOYSTICK_MOSI2,
    output                       JOYSTICK_MISO2,
    output                       JOYSTICK_CS2,

    // SD card ports
    output                       SD_CLK,
    output                       SD_CMD,
    inout                        SD_DAT0,
    inout                        SD_DAT1,
    inout                        SD_DAT2,
    inout                        SD_DAT3,

    // Ports for on-board I2S amplifier
    output                       HP_BCK,
    output                       HP_DIN,
    output                       HP_WS,
    output                       PA_EN,

    // On-board WS2812 RGB LED with a serial interface
    inout                        WS2812
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
        .sio_clk  ( JOYSTICK_CS2   ),
        .sio_stb  ( JOYSTICK_MISO2 )
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

            .PixelClk  (   LCD_CLK        ),
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
            .lr       ( GPIO[1]        ),
            .ws       ( GPIO[2]        ),
            .sck      ( GPIO[3]        ),
            .sd       ( SD_DAT1        ),
            .value    ( mic            )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        // For tang_nano_20k DAC do not require mclk signal
        // but it needs enable signal PA_EN

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
            .bclk     ( HP_BCK       ),
            .lrclk    ( HP_WS        ),
            .sdata    ( HP_DIN       )
        );

        // Enable DAC
        assign PA_EN = 1'b1;

    `endif

endmodule
