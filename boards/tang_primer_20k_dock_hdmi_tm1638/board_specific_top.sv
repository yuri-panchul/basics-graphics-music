`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

`ifdef FORCE_NO_INSTANTIATE_GRAPHICS_INTERFACE_MODULE
   `undef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
`endif

module board_specific_top
# (
    parameter   clk_mhz       = 27,
                pixel_mhz     = 25,

                w_key         = 5,  // The last key is used for a reset
                w_sw          = 5,

                w_led         = 6,

                w_digit       = 1,
                w_gpio        = 32,

                screen_width  = 640,
                screen_height = 480,

                w_red         = 8,
                w_green       = 8,
                w_blue        = 8,

                w_x = $clog2 ( screen_width ),
                w_y = $clog2 ( screen_height ),

                w_sound       = 16
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3,

    output                      TMDS_CLK_N,
    output                      TMDS_CLK_P,
    output [              2:0]  TMDS_D_N,
    output [              2:0]  TMDS_D_P,

    output                      PA_EN,
    output                      HP_DIN,
    output                      HP_WS,
    output                      HP_BCK
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

    wire                      clk;
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
        assign     clk     = pixel_clk;

    `else

        localparam lab_mhz = clk_mhz;
        assign     clk     = CLK;

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

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

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
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_sw        ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),

        .gpio          (               )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        wire [$left (abcdefgh):0] hgfedcba;
        `SWAP_BITS (hgfedcba, abcdefgh);

        tm1638_board_controller
        # (
            .clk_mhz   ( lab_mhz     ),
            .w_digit   ( w_tm_digit  )
        )
        i_tm1638
        (
            .clk       ( clk         ),
            .rst       ( rst         ),
            .hgfedcba  ( hgfedcba    ),
            .digit     ( tm_digit    ),
            .ledr      ( tm_led      ),
            .keys      ( tm_key      ),
            .sio_clk   ( GPIO_1[2]   ),
            .sio_stb   ( GPIO_1[3]   ),
            .sio_data  ( GPIO_1[1]   )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        localparam serial_clk_mhz = 125;

        wire serial_clk;

        Gowin_rPLL i_Gowin_rPLL
        (
            .clkin  ( CLK        ),  // 27 MHz
            .clkout ( serial_clk ),  // 126 MHz
            .lock   (            )
        );

        //--------------------------------------------------------------------

        wire hsync, vsync, display_on, pixel_clk, raw_pixel_clk;

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( serial_clk_mhz ),
            .PIXEL_MHZ   ( pixel_mhz      )
        )
        i_vga
        (
            .clk         ( serial_clk     ),
            .rst         ( rst            ),
            .hsync       ( hsync          ),
            .vsync       ( vsync          ),
            .display_on  ( display_on     ),
            .hpos        ( x10            ),
            .vpos        ( y10            ),
            .pixel_clk   ( raw_pixel_clk  )
        );

        // Works without BUFG, but seems like a good practice

        BUFG i_BUFG (.I (raw_pixel_clk), .O (pixel_clk));

        //--------------------------------------------------------------------

        DVI_TX_Top i_DVI_TX_Top
        (
            .I_rst_n        ( ~ rst         ),
            .I_serial_clk   (   serial_clk  ),
            .I_rgb_clk      (   pixel_clk   ),
            .I_rgb_vs       ( ~ vsync       ),
            .I_rgb_hs       ( ~ hsync       ),
            .I_rgb_de       (   display_on  ),
            .I_rgb_r        (   red         ),
            .I_rgb_g        (   green       ),
            .I_rgb_b        (   blue        ),
            .O_tmds_clk_p   (   TMDS_CLK_P  ),
            .O_tmds_clk_n   (   TMDS_CLK_N  ),
            .O_tmds_data_p  (   TMDS_D_P    ),
            .O_tmds_data_n  (   TMDS_D_N    )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( lab_mhz    )
        )
        i_microphone
        (
            .clk     ( clk        ),
            .rst     ( rst        ),
            .lr      ( GPIO_0 [2] ),
            .ws      ( GPIO_0 [3] ),
            .sck     ( GPIO_0 [1] ),
            .sd      ( GPIO_0 [0] ),
            .value   ( mic        )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        // Onboard PT8211 DAC requires LSB (Least Significant Bit Justified) data format
        // For Tang Primer 20k Dock DAC PT8211 do not require mclk signal but 
        // on-board amplifier LPA4809 needs enable signal PA_EN

        i2s_audio_out
        # (
            .clk_mhz             ( lab_mhz    ),
            .in_res              ( w_sound    ),
            .align_right         ( 1'b1       ), // PT8211 DAC data format
            .offset_by_one_cycle ( 1'b0       )
        )
        i_audio_out
        (
            .clk                 ( clk        ),
            .reset               ( rst        ),
            .data_in             ( sound      ),
            .mclk                (            ),
            .bclk                ( HP_BCK     ),
            .lrclk               ( HP_WS      ),
            .sdata               ( HP_DIN     )
        );

        // Enable DAC
        assign PA_EN = 1'b1;

        // External DAC PCM5102A, Digilent Pmod AMP3, UDA1334A

        i2s_audio_out
        # (
            .clk_mhz             ( lab_mhz    ),
            .in_res              ( w_sound    ),
            .align_right         ( 1'b0       ),
            .offset_by_one_cycle ( 1'b1       )
        )
        i_ext_audio_out
        (
            .clk                 ( clk        ),
            .reset               ( rst        ),
            .data_in             ( sound      ),
            .mclk                ( GPIO_1[4]  ),
            .bclk                ( GPIO_1[5]  ),
            .lrclk               ( GPIO_1[7]  ),
            .sdata               ( GPIO_1[6]  )
        );

    `endif

endmodule
