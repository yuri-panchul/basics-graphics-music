`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

// BrisbaneSilicon BRS-100-GW1NR9 with MuseLab PMOD-RGBLCD adapter,
// TM1638 module, INMP441 microphone and PCM5102 DAC.
//
// The board has no LCD connector, so the LCD, TM1638, microphone
// and DAC are connected to the J5 and J6 headers with jumper wires.
// The FPGA pins are the same as on Tang Nano 9K with a 480x272 LCD,
// and this module follows boards/tang_nano_9k_lcd_480_272_tm1638.

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

              // We use sw as an alias to key on BRS-100,
              // either with or without TM1638

              w_key         = 2,
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 2,

              screen_width  = 480,
              screen_height = 272,

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

    input                        UART_RX,
    output                       UART_TX,

    output                       LCD_DE,
    output                       LCD_VS,
    output                       LCD_HS,
    output                       LCD_CK,

    output [7:7 + 1 - w_red   ]  LCD_R,
    output [7:7 + 1 - w_green ]  LCD_G,
    output [7:7 + 1 - w_blue  ]  LCD_B,

    inout                        TM1638_DIO,
    output                       TM1638_CLK,
    output                       TM1638_STB,

    output                       MIC_LR,
    output                       MIC_WS,
    output                       MIC_SCK,
    input                        MIC_SD,

    output                       DAC_BCK,
    output                       DAC_DIN,
    output                       DAC_LCK,

    // The two header pins left after the peripherals above

    inout  [w_gpio       - 1:0]  GPIO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

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
            .sio_data ( TM1638_DIO     ),
            .sio_clk  ( TM1638_CLK     ),
            .sio_stb  ( TM1638_STB     )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        Gowin_rPLL i_Gowin_rPLL
        (
            .clkout  ( LCD_CK ),  //  9 MHz
            .clkin   ( clk    )   // 27 MHz
        );

        lcd_480_272 i_lcd
        (
            .PixelClk  (   LCD_CK         ),
            .nRST      ( ~ rst            ),

            .LCD_DE    (   LCD_DE         ),
            .LCD_HSYNC (   LCD_HS         ),
            .LCD_VSYNC (   LCD_VS         ),

            .x         (   x              ),
            .y         (   y              )
        );

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
            .sck      ( MIC_SCK        ),
            .sd       ( MIC_SD         ),
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
            .mclk     (                ),  // SCK should be connected to 0 in PCM 5102
            .bclk     ( DAC_BCK        ),  // BCK
            .sdata    ( DAC_DIN        ),  // DIN
            .lrclk    ( DAC_LCK        )   // LCK
        );

    `endif

endmodule
