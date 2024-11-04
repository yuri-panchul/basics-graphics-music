`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

//----------------------------------------------------------------------------

`define FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

`define IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION
`define REVERSE_KEY
`define REVERSE_LED

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 9,

              w_key         = 2,  // The last key is used for a reset
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 5,

              `ifdef USE_LCD_800_480

              screen_width  = 800,
              screen_height = 480,

              `else  // USE_LCD_480_272 or USE_LCD_480_272_ML6485

              screen_width  = 480,
              screen_height = 272,

              `endif

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
    // However we can use LCD_CLK, DE, VS, HS, BL
    // because they are assigned to a different bank.

    output                       LCD_CLK,
    output                       LCD_DE,
    output                       LCD_VS,
    output                       LCD_HS,
    output                       LCD_BL,

    output [7:7 + 1 - w_red   ]  LCD_R,
    output [7:7 + 1 - w_green ]  LCD_G,
    output [7:7 + 1 - w_blue  ]  LCD_B,

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
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else  // TM1638 module is not connected

        // We create a dummy seven-segment digit
        // to avoid errors in the labs with seven-segment display

        localparam w_lab_key   = w_key,
                   w_lab_led   = w_led,
                   w_lab_digit = 1;  // w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        wire rst_on_power_up;
        imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

        wire rst = rst_on_power_up | (| KEY);

    `elsif IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

        wire rst_on_power_up;
        imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

        wire rst = rst_on_power_up;

    `else  // Reset using an on-board button

        `ifdef REVERSE_KEY
            wire rst = KEY [0];
        `else
            wire rst = KEY [w_key - 1];
        `endif

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign lab_key  = tm_key;

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (~ lab_led);

    `else  // `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, KEY);
        `else
            assign lab_key = KEY;
        `endif

        //--------------------------------------------------------------------

        `ifdef REVERSE_LED
            `SWAP_BITS (LED, ~ lab_led);
        `else
            assign LED = ~ lab_led;
    `endif

    `endif  // `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

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

        .w_key         ( w_lab_key     ),
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
        .gpio          ( GPIO          )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

    wire [$left (abcdefgh):0] hgfedcba;
        `SWAP_BITS (hgfedcba, abcdefgh);

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

        `ifdef USE_LCD_800_480

        wire lcd_module_clk;

        Gowin_rPLL i_Gowin_rPLL
        (
            .clkout  ( lcd_module_clk ),  // 200    MHz
            .clkoutd ( LCD_CLK        ),  //  33.33 MHz
            .clkin   ( clk            )   //  27    MHz
        );

        `else  // Using 480x272

            Gowin_rPLL i_Gowin_rPLL
            (
                .clkout ( LCD_CLK ),  //  9 MHz
                .clkin  ( clk     )   // 27 MHz
            );

        `endif

        `ifdef USE_LCD_800_480
        lcd_800_480
        `else
        lcd_480_272
        `endif
        i_lcd
        (
            `ifdef USE_LCD_800_480
            .CLK       (   lcd_module_clk ),
            `endif

            .PixelClk  (   LCD_CLK        ),
            .nRST      ( ~ rst            ),

            .LCD_DE    (   LCD_DE         ),
            .LCD_HSYNC (                  ),
            .LCD_VSYNC (                  ),

            .x         (   x              ),
            .y         (   y              )
        );

        assign LCD_HS = 1'b0;
        assign LCD_VS = 1'b0;

        assign LCD_BL = 1'b1;

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
