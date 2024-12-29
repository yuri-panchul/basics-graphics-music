`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

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

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 27,

              // We use sw as an alias to key on Tang Nano 9K,
              // either with or without TM1638

              w_key         = 2,
              w_sw          = 0,
              w_led         = 1,
              w_digit       = 0,
              w_gpio        = 2,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                 CLK,
    input  [w_key - 1:0]  KEY,
    output                LED,

    inout                 FLASH_CLK,   // TM1638 STB
    inout                 FLASH_DI,    // TM1638 CLK
    inout                 FLASH_DO,    // TM1638 DIO

    output                TMDS_CLK_N,
    output                TMDS_CLK_P,
    output [        2:0]  TMDS_D_N,
    output [        2:0]  TMDS_D_P,

    inout                 FLASH_CS,    // INMP441 SCK
    inout                 FLASH_WP,    // INMP441 WS
    inout                 FLASH_HOLD,  // INMP441 L/R

    inout                 CAM_SCL,     // GPIO[0]
    inout                 CAM_SDA,     // GPIO[1]
    inout                 DVP_VSYNC,   // PCM5102 LCK
    inout                 DVP_HSYNC,   // PCM5102 DIN
    inout                 DVP_PCLK,    // PCM5102 BCK
    inout                 PIXDATA9,    // PCM5102 SCK
    inout                 PIXDATA8     // INMP441 SD
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
        // to avoid errors in the labs with seven-segment display,
        // and extra dummy LED for the same purpose.

        localparam w_lab_key   = w_key,
                   w_lab_led   = 2,  // w_led,
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

    wire  [w_red       - 1:0] red   = lab_red   ^ { w_red   { vtm_red   } };
    wire  [w_green     - 1:0] green = lab_green ^ { w_green { vtm_green } };
    wire  [w_blue      - 1:0] blue  = lab_blue  ^ { w_blue  { vtm_blue  } };

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

        assign LED      = w_led' (lab_led);

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        // Virtual tm1638 - tm_keys are input, not output

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY);
        `else
            assign lab_key = ~ KEY;
        `endif

        assign tm_key   = lab_key;
        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (lab_led);

    `else  // no any form of TM1638

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY);
        `else
            assign lab_key = ~ KEY;
        `endif

        assign LED = w_led' (lab_led);

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

        .uart_rx       (               ),
        .uart_tx       (               ),

        .mic           ( mic           ),
        .sound         ( sound         ),

        .gpio          ( { CAM_SDA,
                           CAM_SCL  }  )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;
    `SWAP_BITS (hgfedcba, abcdefgh);

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz    ),
            .w_digit  ( w_tm_digit )
        )
        i_tm1638
        (
            .clk      ( clk        ),
            .rst      ( rst        ),
            .hgfedcba ( hgfedcba   ),
            .digit    ( tm_digit   ),
            .ledr     ( tm_led     ),
            .keys     ( tm_key     ),
            .sio_data ( FLASH_DO   ),
            .sio_clk  ( FLASH_DI   ),
            .sio_stb  ( FLASH_CLK  )
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
                .clk           ( clk           ),
                .rst           ( rst           ),
                .hgfedcba      ( hgfedcba      ),
                .digit         ( tm_digit      ),
                .ledr          ( tm_led        ),
                .keys          ( tm_key        ),
                .x             ( x             ),
                .y             ( y             ),
                .red           ( vtm_red       ),
                .green         ( vtm_green     ),
                .blue          ( vtm_blue      )
            );

        `endif

        //--------------------------------------------------------------------

        wire hsync, vsync, display_on;

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ    ( clk_mhz    ),
            .PIXEL_MHZ  ( pixel_mhz  )
        )
        i_vga
        (
            .clk        ( clk        ),
            .rst        ( rst        ),
            .hsync      ( hsync      ),
            .vsync      ( vsync      ),
            .display_on ( display_on ),
            .hpos       ( x10        ),
            .vpos       ( y10        ),
            .pixel_clk  (            )
        );

        //--------------------------------------------------------------------

        DVI_TX_Top i_DVI_TX_Top
        (
            .I_rst_n       ( ~ rst         ),
            .I_rgb_clk     (   clk         ),
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
            .clk_mhz  ( clk_mhz )
        )
        i_microphone
        (
            .clk      ( clk        ),
            .rst      ( rst        ),
            .lr       ( FLASH_HOLD ),  // INMP441 L/R
            .ws       ( FLASH_WP   ),  // INMP441 WS
            .sck      ( FLASH_CS   ),  // INMP441 SCK
            .sd       ( PIXDATA8   ),  // INMP441 SD
            .value    ( mic        )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz  ( clk_mhz   )
        )
        inst_audio_out
        (
            .clk      ( clk       ),
            .reset    ( rst       ),
            .data_in  ( sound     ),
            .mclk     ( PIXDATA9  ),  // PCM5102 SCK
            .bclk     ( DVP_PCLK  ),  //         BCK
            .sdata    ( DVP_HSYNC ),  //         DIN
            .lrclk    ( DVP_VSYNC )   //         LCK
        );

    `endif

endmodule
