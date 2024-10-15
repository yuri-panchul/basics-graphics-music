`include "config.svh"
`include "lab_specific_board_config.svh"

`ifndef HUB75E_LED_MATRIX_BRIGHTNESS
`define HUB75E_LED_MATRIX_BRIGHTNESS 1
`endif

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz           = 50,
              pixel_mhz         = 25,

              // We use sw as an alias to key on Tang Prime 25K,
              // either with or without TM1638

              w_key             = 2,
              w_sw              = 0,
              w_led             = 0,
              w_digit           = 0,

              `ifdef USE_PMOD_DVI

                  w_gpio        = 32,

                  w_red         = 8,
                  w_green       = 8,
                  w_blue        = 8,

                  screen_width  = 640,
                  screen_height = 480,

              `elsif USE_HUB75E_LED_MATRIX

                  w_gpio        = 38,

                  w_red         = 1,
                  w_green       = 1,
                  w_blue        = 1,

                  screen_width  = 64,
                  screen_height = 64,

              `else  // USE_PMOD_VGA

                  w_gpio        = 38,

                  w_red         = 4,
                  w_green       = 4,
                  w_blue        = 4,

                  screen_width  = 640,
                  screen_height = 480,

              `endif

              w_x               = $clog2 ( screen_width  ),
              w_y               = $clog2 ( screen_height )

              // gpio 0..5 are reserved for INMP 441 I2S microphone.
              // PMOD_2 is used for I2S audio (bottom row) and TM1638 (top row).
)

//----------------------------------------------------------------------------

(
    input                  CLK,

    input  [w_key  - 1:0]  KEY,

    input                  UART_RX,
    output                 UART_TX,

    inout  [w_gpio - 1:0]  GPIO,

    `ifdef USE_PMOD_DVI

    output                 TMDS_0_CLK_N,
    output                 TMDS_0_CLK_P,
    output [         2:0]  TMDS_0_D_N,
    output [         2:0]  TMDS_0_D_P,

    // TMDS_1 conflict with TMDS_0

    `else

    inout  [         7:0]  PMOD_0,
    inout  [         7:0]  PMOD_1,

    `endif

    inout  [         7:0]  PMOD_2
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    //------------------------------------------------------------------------

    // Keys, LEDs, seven segment display

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    wire  [              7:0] abcdefgh;

    // Graphics

    wire                 display_on;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] red;
    wire  [w_green     - 1:0] green;
    wire  [w_blue      - 1:0] blue;

    // Sound

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    wire rst_on_power_up;
    imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

    wire tm_rst;

    // `define USE_KEY_0_AS_TM_RESET

    `ifdef USE_KEY_0_AS_TM_RESET
        assign tm_rst  = rst_on_power_up | KEY [0];
    `else
        assign tm_rst  = rst_on_power_up;
    `endif

    wire                  rst     = tm_rst | tm_key [w_tm_key - 1];
    wire [w_tm_key - 1:0] lab_key = tm_key | w_tm_key' (KEY);

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_tm_key      ),
        .w_sw          ( w_tm_key      ),
        .w_led         ( w_tm_led      ),
        .w_digit       ( w_tm_digit    ),
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

        .led           ( tm_led        ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( tm_digit      ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

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
            .rst      ( tm_rst     ),
            .hgfedcba ( hgfedcba   ),
            .digit    ( tm_digit   ),
            .ledr     ( tm_led     ),
            .keys     ( tm_key     ),
            .sio_data ( PMOD_2 [1] ),
            .sio_clk  ( PMOD_2 [2] ),
            .sio_stb  ( PMOD_2 [3] )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire vga_in_clk;

        `ifdef USE_PMOD_DVI

            localparam vga_in_clk_mhz = 125;

            Gowin_PLL i_gowin_pll
            (
                .lock    (            ),
                .clkout0 ( vga_in_clk ),
                .clkin   ( clk        )
            );

        `else  // Instead of DVI use VGA

            localparam vga_in_clk_mhz = clk_mhz;
            assign     vga_in_clk     = clk;

        `endif

        //--------------------------------------------------------------------

        `ifndef USE_HUB75E_LED_MATRIX

            wire hsync, vsync, display_on, pixel_clk;

            wire [9:0] x10; assign x = x10;
            wire [9:0] y10; assign y = y10;

            vga
            # (
                .CLK_MHZ     ( vga_in_clk_mhz ),
                .PIXEL_MHZ   ( pixel_mhz      )
            )
            i_vga
            (
                .clk         ( vga_in_clk     ),
                .rst         ( rst            ),
                .hsync       ( hsync          ),
                .vsync       ( vsync          ),
                .display_on  ( display_on     ),
                .hpos        ( x10            ),
                .vpos        ( y10            ),
                .pixel_clk   ( pixel_clk      )
            );

        `endif

        //--------------------------------------------------------------------

        `ifdef USE_PMOD_DVI

            DVI_TX_Top i_DVI_TX_Top
            (
                .I_rst_n       ( ~ rst          ),
                .I_serial_clk  (   vga_in_clk   ),
                .I_rgb_clk     (   pixel_clk    ),
                .I_rgb_vs      ( ~ vsync        ),
                .I_rgb_hs      ( ~ hsync        ),
                .I_rgb_de      (   display_on   ),
                .I_rgb_r       (   red          ),
                .I_rgb_g       (   green        ),
                .I_rgb_b       (   blue         ),
                .O_tmds_clk_p  (   TMDS_0_CLK_P ),
                .O_tmds_clk_n  (   TMDS_0_CLK_N ),
                .O_tmds_data_p (   TMDS_0_D_P   ),
                .O_tmds_data_n (   TMDS_0_D_N   )
            );

        `elsif USE_HUB75E_LED_MATRIX

            hub75e_led_matrix
            # (
                .clk_mhz       ( clk_mhz                       ),

                .screen_width  ( screen_width                  ),
                .screen_height ( screen_height                 ),

                .w_red         ( w_red                         ),
                .w_green       ( w_green                       ),
                .w_blue        ( w_blue                        ),

                .brightness    ( `HUB75E_LED_MATRIX_BRIGHTNESS )
            )
            i_led_matrix
            (
                .clk     ( clk        ),
                .rst     ( rst        ),

                .x       ( x          ),
                .y       ( y          ),

                .red     ( red        ),
                .green   ( green      ),
                .blue    ( blue       ),

                .ck      ( PMOD_0 [6] ),
                .oe      ( PMOD_0 [7] ),
                .st      ( PMOD_0 [2] ),

                .a       ( PMOD_0 [4] ),
                .b       ( PMOD_0 [0] ),
                .c       ( PMOD_0 [5] ),
                .d       ( PMOD_0 [1] ),
                .e       ( PMOD_1 [3] ),

                .r1      ( PMOD_1 [4] ),
                .r2      ( PMOD_1 [6] ),

                .g1      ( PMOD_1 [0] ),
                .g2      ( PMOD_1 [2] ),

                .b1      ( PMOD_1 [5] ),
                .b2      ( PMOD_1 [7] )
            );

        `else  // PMOD_VGA

            wire  [w_red   - 1:0] red_corrected   = display_on ? red   : '0;
            wire  [w_green - 1:0] green_corrected = display_on ? green : '0;
            wire  [w_blue  - 1:0] blue_corrected  = display_on ? blue  : '0;

            // 4' () conversions are not needed for this configuration,
            // but we put them here for clarity

            assign PMOD_0 = { 4' ( green_corrected ), 2'b0, vsync, hsync    };
            assign PMOD_1 = { 4' ( red_corrected   ), 4' ( blue_corrected ) };

        `endif

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz    )
        )
        i_microphone
        (
            .clk     ( clk        ),
            .rst     ( rst        ),
            .lr      ( GPIO   [0] ),
            .ws      ( GPIO   [2] ),
            .sck     ( GPIO   [4] ),
            .sd      ( GPIO   [5] ),
            .value   ( mic        )
        );

        assign GPIO [1] = 1'b0;  // GND
        assign GPIO [3] = 1'b1;  // VCC

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz    )
        )
        inst_audio_out
        (
            .clk     ( clk        ),
            .reset   ( rst        ),
            .data_in ( sound      ),

            .mclk    ( PMOD_2 [4] ),
            .bclk    ( PMOD_2 [5] ),
            .sdata   ( PMOD_2 [6] ),
            .lrclk   ( PMOD_2 [7] )
        );

    `endif

endmodule
