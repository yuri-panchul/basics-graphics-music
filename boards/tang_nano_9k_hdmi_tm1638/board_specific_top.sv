`include "config.svh"
`include "lab_specific_board_config.svh"

//----------------------------------------------------------------------------

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        `ifndef FORCE_NO_VIRTUAL_TM1638_USING_GRAPHICS
            `define INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        `endif
    `endif
`endif

`define IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION
`define REVERSE_KEY
`define REVERSE_LED

//----------------------------------------------------------------------------

`define SWAP_BITS(dst, src)                                      \
                                                                 \
    generate                                                     \
        genvar dst``_i;                                          \
                                                                 \
        for (dst``_i = 0; dst``_i < $bits (dst); dst``_i ++)     \
        begin : dst``_label                                      \
            assign dst [dst``_i] = src [$left (dst) - dst``_i];  \
        end                                                      \
    endgenerate                                                  \

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 25,

              // We use sw as an alias to key on Tang Nano 9K,
              // either with or without TM1638

              w_key         = 2,
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 10,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        CLK,

    input  [w_key        - 1:0]  KEY,

    output [w_led        - 1:0]  LED,

    // Some LARGE_LCD pins share bank with TMDS pins
    // which have different voltage requirements.
    //
    // However we can use LARGE_LCD_DE, VS, HS, CK,
    // because they are assigned to a different bank.

       output                    LARGE_LCD_DE,
       output                    LARGE_LCD_VS,
       output                    LARGE_LCD_HS,
       output                    LARGE_LCD_CK,
    // output                    LARGE_LCD_INIT,
    // output                    LARGE_LCD_BL,

    // output [            4:0]  LARGE_LCD_R,
    // output [            5:0]  LARGE_LCD_G,
    // output [            4:0]  LARGE_LCD_B,

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
    // share bank with TMDS pins
    // which have different voltage requirements.
    //
    // It means we cannot use them
    // for I2S audio output module PCM5102
    // in basics-graphics-music labs
    // when we use HDMI interface

    // inout                     SMALL_LCD_CLK,
    // inout                     SMALL_LCD_RESETN,
    // inout                     SMALL_LCD_CS,
    // inout                     SMALL_LCD_RS,
    // inout                     SMALL_LCD_DATA,

    output                       TMDS_CLK_N,
    output                       TMDS_CLK_P,
    output [               2:0]  TMDS_D_N,
    output [               2:0]  TMDS_D_P

    // This pins have bank conflict when used with HDMI

    // ,
    // output                    FLASH_CLK,
    // output                    FLASH_CSB,
    // output                    FLASH_MOSI,
    // input                     FLASH_MISO
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

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        // Instantiate virtual tm1638
        localparam w_lab_key   = w_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;
    `else
        // No need in TM1638 in any form
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

    wire  [w_red       - 1:0] lab_red;
    wire  [w_green     - 1:0] lab_green;
    wire  [w_blue      - 1:0] lab_blue;
    wire  vtm_red, vtm_green, vtm_blue;
    wire  [w_red       - 1:0] red   =   lab_red ^ { w_red   { vtm_red } };
    wire  [w_green     - 1:0] green = lab_green ^ { w_green { vtm_green } };
    wire  [w_blue      - 1:0] blue  =  lab_blue ^ { w_blue  { vtm_blue } };

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

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;
        assign lab_key  = tm_key;

        assign LED      = w_led' (~ lab_led);

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        // Virtual tm1638 - tm_keys are input, not output

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY);
        `else
            assign lab_key = ~ KEY;
        `endif

        assign tm_key  = lab_key;
        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (~ lab_led);

    `else  // no any form of TM1638

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

        .x             ( x             ),
        .y             ( y             ),
        .red           ( lab_red       ),
        .green         ( lab_green     ),
        .blue          ( lab_blue      ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          ( GPIO          )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

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

        `ifdef INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
            virtual_tm1638_using_graphics
            # (
                .w_digit       ( w_tm_digit    ),
                .screen_width  ( screen_width  ),
                .screen_height ( screen_height )
            )
            i_tm1638_virtual
            (
                .clk      ( clk           ),
                .rst      ( rst           ),
                .hgfedcba ( hgfedcba      ),
                .digit    ( tm_digit      ),
                .ledr     ( tm_led        ),
                .keys     ( tm_key        ),
                .x        ( x             ),
                .y        ( y             ),
                .red      ( vtm_red       ),
                .green    ( vtm_green     ),
                .blue     ( vtm_blue      )
            );

        `endif

        localparam serial_clk_mhz = 125;

        wire serial_clk;

        Gowin_rPLL i_Gowin_rPLL
        (
            .clkin  ( clk        ),
            .clkout ( serial_clk ),
            .lock   (            )
        );

        // Do we need to put serial_clk through BUFG?
        // BUFG i_BUFG (.I (raw_serial_clk), .O (serial_clk));

        //--------------------------------------------------------------------

        wire hsync, vsync, display_on, pixel_clk;

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( serial_clk_mhz  ),
            .PIXEL_MHZ   ( pixel_mhz       )
        )
        i_vga
        (
            .clk         ( serial_clk      ),
            .rst         ( rst             ),
            .hsync       ( hsync           ),
            .vsync       ( vsync           ),
            .display_on  ( display_on      ),
            .hpos        ( x10             ),
            .vpos        ( y10             ),
            .pixel_clk   ( pixel_clk       )
        );

        //--------------------------------------------------------------------

        DVI_TX_Top i_DVI_TX_Top
        (
            .I_rst_n       ( ~ rst         ),
            .I_serial_clk  (   serial_clk  ),
            .I_rgb_clk     (   pixel_clk   ),
            .I_rgb_vs      ( ~ vsync       ),
            .I_rgb_hs      ( ~ hsync       ),
            .I_rgb_de      (   display_on  ),
            .I_rgb_r       (   red         ),
            .I_rgb_g       (   green       ),
            .I_rgb_b       (   blue        ),
            .O_tmds_clk_p  (   TMDS_CLK_P  ),
            .O_tmds_clk_n  (   TMDS_CLK_N  ),
            .O_tmds_data_p (   TMDS_D_P    ),
            .O_tmds_data_n (   TMDS_D_N    )
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
            .clk_mhz  ( clk_mhz      )
        )
        inst_audio_out
        (
            .clk      ( clk          ),
            .reset    ( rst          ),
            .data_in  ( sound        ),
            .mclk     ( LARGE_LCD_DE ),
            .bclk     ( LARGE_LCD_VS ),
            .lrclk    ( LARGE_LCD_HS ),
            .sdata    ( LARGE_LCD_CK )
        );

    `endif

endmodule
