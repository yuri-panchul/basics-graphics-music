`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

// BrisbaneSilicon BRS-100-GW1NR9 with MuseLab PMOD-RGBLCD adapter,
// TM1638 module, INMP441 microphone and PCM5102 DAC.
//
// board_specific.cst is the constraint file of the board manufacturer.
// It names the 32 header pins pad_io[1..32], and this module decides
// which of them carry the LCD, TM1638, microphone and DAC signals.
// The FPGA pins are the same as on Tang Nano 9K with a 480x272 LCD,
// and this module follows boards/tang_nano_9k_lcd_480_272_tm1638.
//
// pad_io[1..16] are the pins 1..16 of header J5,
// pad_io[17..32] are the pins 1..16 of header J6.

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
              w_gpio        = 2,  // pad_io [18:17], J6.1 and J6.2

              screen_width  = 480,
              screen_height = 272,

              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        pad_clk_27Mhz,

    input  [             2:1]    pad_user_buttons_n,
    output [             6:1]    pad_leds_n,

    output                       pad_ser_tx,
    input                        pad_ser_rx,

    inout  [            32:1]    pad_io,

    // The SPI flash pins are not used by the labs

    inout                        pad_flash_clk,
    inout                        pad_flash_csb,
    inout                        pad_flash_mosi,
    inout                        pad_flash_miso
);

    wire clk = pad_clk_27Mhz;

    //------------------------------------------------------------------------
    // Buttons and LEDs, in the order of Tang Nano 9K:
    // KEY [0] is FPGA pin 4 and LED [0] is FPGA pin 10.

    wire [w_key - 1:0] KEY = { pad_user_buttons_n [1], pad_user_buttons_n [2] };
    wire [w_led - 1:0] LED;

    assign pad_leds_n = { LED [0], LED [1], LED [2], LED [3], LED [4], LED [5] };

    wire UART_RX = pad_ser_rx;
    wire UART_TX;

    assign pad_ser_tx = UART_TX;

    //------------------------------------------------------------------------
    // Header pins. See README.md for the wiring.

    wire                         LCD_DE;
    wire                         LCD_VS;
    wire                         LCD_HS;
    wire                         LCD_CK;

    wire [7:7 + 1 - w_red   ]    LCD_R;
    wire [7:7 + 1 - w_green ]    LCD_G;
    wire [7:7 + 1 - w_blue  ]    LCD_B;

    // pad_io [1..3] are J5.1..3, TM1638 DIO, CLK and STB,
    // connected in tm1638_board_controller instance below

    // pad_io [4..6] are J5.4..6, PCM5102 BCK, DIN and LCK,
    // connected in i2s_audio_out instance below

    assign pad_io [ 7] = LCD_DE;      // J5.7   PMOD-RGBLCD J2.13
    assign pad_io [ 8] = LCD_VS;      // J5.8   J2.12
    assign pad_io [ 9] = LCD_CK;      // J5.9   J2.10

    // pad_io [10..13] are J5.10..13, INMP441 SCK, WS, L/R and SD,
    // connected in inmp441_mic_i2s_receiver instance below

    assign pad_io [14] = LCD_HS;      // J5.14  J2.11
    assign pad_io [15] = LCD_B [7];   // J5.15  J2.18  B4
    assign pad_io [16] = LCD_B [6];   // J5.16  J2.19  B3

    // pad_io [17..18] are J6.1..2, the GPIO of the labs

    assign pad_io [19] = LCD_R [3];   // J6.3   J2.30  R0
    assign pad_io [20] = LCD_R [4];   // J6.4   J2.29  R1
    assign pad_io [21] = LCD_R [5];   // J6.5   J2.28  R2
    assign pad_io [22] = LCD_R [6];   // J6.6   J2.27  R3
    assign pad_io [23] = LCD_R [7];   // J6.7   J2.24  R4

    assign pad_io [24] = LCD_G [2];   // J6.8   J2.1   G0
    assign pad_io [25] = LCD_G [3];   // J6.9   J2.2   G1
    assign pad_io [26] = LCD_G [4];   // J6.10  J2.3   G2
    assign pad_io [27] = LCD_G [5];   // J6.11  J2.4   G3
    assign pad_io [28] = LCD_G [6];   // J6.12  J2.7   G4
    assign pad_io [29] = LCD_G [7];   // J6.13  J2.9   G5

    assign pad_io [30] = LCD_B [3];   // J6.14  J2.22  B0
    assign pad_io [31] = LCD_B [4];   // J6.15  J2.21  B1
    assign pad_io [32] = LCD_B [5];   // J6.16  J2.20  B2

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
        .gpio          ( pad_io [18:17] )
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
            .sio_data ( pad_io [ 1]    ),  // J5.1
            .sio_clk  ( pad_io [ 2]    ),  // J5.2
            .sio_stb  ( pad_io [ 3]    )   // J5.3
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
            .lr       ( pad_io [12]    ),  // J5.12
            .ws       ( pad_io [11]    ),  // J5.11
            .sck      ( pad_io [10]    ),  // J5.10
            .sd       ( pad_io [13]    ),  // J5.13
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
            .bclk     ( pad_io [ 4]    ),  // J5.4  BCK
            .sdata    ( pad_io [ 5]    ),  // J5.5  DIN
            .lrclk    ( pad_io [ 6]    )   // J5.6  LCK
        );

    `endif

endmodule
