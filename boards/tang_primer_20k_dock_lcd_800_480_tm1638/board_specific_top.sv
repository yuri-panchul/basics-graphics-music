`include "config.svh"
`include "lab_specific_board_config.svh"

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

`ifdef FORCE_NO_INSTANTIATE_GRAPHICS_INTERFACE_MODULE
   `undef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
`endif

module board_specific_top
# (
    parameter   clk_mhz       = 27, // CLK - lab_clk lab_mhz
                pixel_mhz     = 32, // LCD_CLK - lab_clk lab_mhz

                w_key         = 5,  // The last key is used for a reset
                w_sw          = 5,

                w_led         = 6,

                w_digit       = 0,
                w_gpio        = 32,

                screen_width  = 800,
                screen_height = 480,

                w_red         = 5,
                w_green       = 6,
                w_blue        = 5,

                w_x = $clog2 ( screen_width  ),
                w_y = $clog2 ( screen_height )
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    output                      LCD_DE,
    output                      LCD_VS,
    output                      LCD_HS,
    output                      LCD_CLK,
    output                      LCD_BL,

    output [              4:0]  LCD_R,
    output [              5:0]  LCD_G,
    output [              4:0]  LCD_B,

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3,

    inout                       EDID_CLK,
    inout                       EDID_DAT,

    output                      PA_EN,
    output                      HP_DIN,
    output                      HP_WS,
    output                      HP_BCK,

    output                      SCK,
    output                      BCK,
    output                      LRCK,
    output                      DIN

);

        Gowin_rPLL i_Gowin_rPLL
        (
            .clkout   (                ),  //  96 MHz
            .clkoutd  (                ),  //  48 MHz
            .clkoutd3 ( LCD_CLK        ),  //  32 MHz
            .clkin    ( CLK            )   //  27 MHz
        );

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

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
    logic [w_lab_sw    - 1:0] lab_sw;
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

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        localparam lab_mhz = pixel_mhz;
        assign     lab_clk = LCD_CLK;
        assign     LCD_BL  = ~ rst;

    `else

        localparam lab_mhz = clk_mhz;
        assign     lab_clk = CLK;
        assign     LCD_BL  = 1'b0;

    `endif

    //------------------------------------------------------------------------

    // Always use button on board for reset, otherwise the board would be
    // stuck on reset if tm1638 is not connected
    assign rst = ~ KEY [w_key - 1];

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign lab_key  = tm_key [w_tm_key - 1:0];
        assign lab_sw   = ~ SW;

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

        assign lab_key  = ~ KEY [w_key - 1:0];
        assign lab_sw   = ~ SW;

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (lab_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .clk (lab_clk), .rst (rst));

    //------------------------------------------------------------------------

    // Mirrored LCD
    //wire  [w_x - 1:0] mirrored_x = w_x' (screen_width  - 1 - x);
    //wire  [w_y - 1:0] mirrored_y = w_y' (screen_height - 1 - y);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( lab_mhz       ),

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
        .clk           ( lab_clk       ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_sw        ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

      // Normal LCD
        .x             ( x             ),
        .y             ( y             ),

      // Mirrored LCD
      //.x             ( mirrored_x    ),
      //.y             ( mirrored_y    ),

        .red           ( LCD_R         ),
        .green         ( LCD_G         ),
        .blue          ( LCD_B         ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          (               )
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

    //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .clk_mhz ( lab_mhz    ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk        ( lab_clk       ),
        .rst        ( rst           ),
        .hgfedcba   ( hgfedcba      ),
        .digit      ( tm_digit      ),
        .ledr       ( tm_led        ),
        .keys       ( tm_key        ),
        .sio_clk    ( GPIO_0[2]     ),
        .sio_stb    ( GPIO_0[3]     ),
        .sio_data   ( GPIO_0[1]     )
    );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        lcd_800_480 i_lcd
        (
            .PixelClk  (   lab_clk        ),
            .nRST      ( ~ rst            ),

            .LCD_DE    (   LCD_DE         ),
            .LCD_HSYNC (   LCD_HS         ),
            .LCD_VSYNC (   LCD_VS         ),

            .x         (   x              ),
            .y         (   y              )
        );

    `endif

    //--------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( lab_mhz    )
    )
    i_microphone
    (
        .clk     ( lab_clk    ),
        .rst     ( rst        ),
        .lr      ( GPIO_1 [1] ),
        .ws      ( GPIO_1 [2] ),
        .sck     ( GPIO_1 [3] ),
        .sd      ( GPIO_1 [0] ),
        .value   ( mic        )
    );

    `endif

    //--------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

    // Onboard PT8211 DAC Tang Primer 20k dock board

    /* About the parameter align_right. Shifting the data to the right. 
    PT8211 DAC requires Japanese or called LSB (Least Significant Bit Justified) 
    data format (LSB data at the end of the packet). With respect to I2C shifted 
    to the right by 1 bit, this will be 15 bits. The width of the data bus in the 
    driver i2s_audio_out.sv It is used to determine the distance between the first 
    bit configured for I2S operation (shifted 1 bit to the right) and LSB data. */

    i2s_audio_out
    # (
        .clk_mhz  ( lab_mhz    ),
        .align_right ( 1'b1    )
    )
    inst_audio_out
    (
        .clk      ( lab_clk    ),
        .reset    ( rst        ),
        .data_in  ( sound      ),
        .mclk     (            ),
        .bclk     ( HP_BCK     ),
        .lrclk    ( HP_WS      ),
        .sdata    ( HP_DIN     )
    );

    // Enable DAC

    // For Tang Primer 20k dock DAC do not require mclk signal
    // but it needs enable signal PA_EN

    assign PA_EN = 1'b1;

    // External DAC PCM5102A, Digilent Pmod AMP3, UDA1334A

    i2s_audio_out
    # (
        .clk_mhz  ( lab_mhz    )
    )
    inst_ext_audio_out
    (
        .clk      ( lab_clk    ),
        .reset    ( rst        ),
        .data_in  ( sound      ),
        .mclk     ( SCK        ),
        .bclk     ( BCK        ),
        .sdata    ( DIN        ),
        .lrclk    ( LRCK       )
    );

    `endif

endmodule
