`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

//----------------------------------------------------------------------------

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

`define IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION
`define REVERSE_KEY
`define REVERSE_LED

// `define MIRROR_LCD

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 9,

              // We use sw as an alias to key on Tang Nano 9K,
              // either with or without TM1638

              w_key         = 2,
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 6,

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

    // TMDS pins conflict with LARGE_LCD pins

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

        wire rst = rst_on_power_up | (| (~ KEY));

    `elsif IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

        wire rst_on_power_up;
        imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

        wire rst = rst_on_power_up;

    `else  // Reset using an on-board button

        `ifdef REVERSE_KEY
            wire rst = ~ KEY [0];
        `else
            wire rst = ~ KEY [w_key - 1];
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
            `SWAP_BITS (lab_key, ~ KEY);
        `else
            assign lab_key = ~ KEY;
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

    `ifdef MIRROR_LCD

    wire  [w_x - 1:0] mirrored_x = w_x' (screen_width  - 1 - x);
    wire  [w_y - 1:0] mirrored_y = w_y' (screen_height - 1 - y);

    `endif

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

        `ifdef MIRROR_LCD

        .x             ( mirrored_x    ),
        .y             ( mirrored_y    ),

        `else

        .x             ( x             ),
        .y             ( y             ),

        `endif

        .red           ( LARGE_LCD_R   ),
        .green         ( LARGE_LCD_G   ),
        .blue          ( LARGE_LCD_B   ),

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

        `ifdef USE_LCD_800_480

            Gowin_rPLL i_Gowin_rPLL
            (
                .clkout  (              ),  // 200    MHz
                .clkoutd ( LARGE_LCD_CK ),  //  33.33 MHz
                .clkin   ( clk          )   //  27    MHz
            );

        `elsif USE_LCD_480_272_ML6485

            Gowin_rPLL i_Gowin_rPLL
            (
                .clkout  (              ),  // 200    MHz
                .clkoutd ( LARGE_LCD_CK ),  //  33.33 MHz
                .clkin   ( clk          )   //  27    MHz
            );

        `else  // Using 480x272

            Gowin_rPLL i_Gowin_rPLL
            (
                .clkout  ( LARGE_LCD_CK ),  //  9 MHz
                .clkin   ( clk          )   // 27 MHz
            );

        `endif

        `ifdef USE_LCD_800_480
        lcd_800_480
        `elsif USE_LCD_480_272_ML6485
        lcd_480_272_ml6485
        `else
        lcd_480_272
        `endif
        i_lcd
        (
            .PixelClk  (   LARGE_LCD_CK   ),
            .nRST      ( ~ rst            ),

            .LCD_DE    (   LARGE_LCD_DE   ),
            .LCD_HSYNC (   LARGE_LCD_HS   ),
            .LCD_VSYNC (   LARGE_LCD_VS   ),

            .x         (   x              ),
            .y         (   y              )
        );

        assign LARGE_LCD_INIT = 1'b0;
        assign LARGE_LCD_BL   = 1'b0;

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
            .lr       ( TF_CS          ),
            .ws       ( TF_MOSI        ),
            .sck      ( TF_SCLK        ),
            .sd       ( TF_MISO        ),
            .value    ( mic            )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz  ( clk_mhz        )
        )
        inst_audio_out
        (
            .clk      ( clk            ),
            .reset    ( rst            ),
            .data_in  ( sound          ),
            .mclk     ( SMALL_LCD_DATA ),
            .bclk     ( SMALL_LCD_CLK  ),
            .lrclk    ( SMALL_LCD_RS   ),
            .sdata    ( SMALL_LCD_CS   )
        );

    `endif

endmodule
