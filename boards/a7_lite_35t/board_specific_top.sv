`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 2,
              w_sw          = 0,
              w_led         = 2,
              w_digit       = 0,
              w_gpio        = 13,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                        CLK_50M,
    input                        RESETN,

    input  [w_key        - 1:0]  KEY,

    output [w_led        - 1:0]  LED,

    output                       TMDS_CLK_N,
    output                       TMDS_CLK_P,
    output [               2:0]  TMDS_D_N,
    output [               2:0]  TMDS_D_P,

    inout  [w_gpio       - 1:0]  GPIO,

    input                        UART_RX,
    output                       UART_TX
);

    //------------------------------------------------------------------------

    clk_wiz i_clk_wiz
    (
        .clk_out1   ( serial_clk ),  // 250 mhz
        .clk_out2   ( clk        ),  // 50 mhz
        .clk_out3   ( pixel_clk  ),  // 25 mhz
        .clk_in1    ( CLK_50M    )   // 50 mhz
    );

    xpm_cdc_async_rst i_xpm_cdc_async_rst
    (
       .dest_clk    (   clk       ),
       .dest_arst   (   rst       ),
       .src_arst    ( ~ RESETN    )
    );

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
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

    wire  [w_red       - 1:0] red   = lab_red   ^ { w_red   { vtm_red   } };
    wire  [w_green     - 1:0] green = lab_green ^ { w_green { vtm_green } };
    wire  [w_blue      - 1:0] blue  = lab_blue  ^ { w_blue  { vtm_blue  } };

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;
        assign lab_key  = tm_key;

        assign LED      = w_led' (~ lab_led);

    `else  // no any form of TM1638

        assign lab_key = ~ KEY;

        assign LED = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (    clk_mhz           ),
        .w_key         (    w_lab_key         ),
        .w_sw          (    w_lab_key         ),
        .w_led         (    w_lab_led         ),
        .w_digit       (    w_lab_digit       ),
        .w_gpio        (    w_gpio            ),

        .screen_width  (   screen_width       ),
        .screen_height (   screen_height      ),

        .w_red         (   w_red              ),
        .w_green       (   w_green            ),
        .w_blue        (   w_blue             )
    )
    i_lab_top
    (
        .clk           (   clk                ),
        .slow_clk      (   slow_clk           ),
        .rst           (   rst                ),

        .key           (   lab_key            ),
        .sw            (   lab_key            ),

        .led           (   lab_led            ),

        .abcdefgh      (   abcdefgh           ),
        .digit         (   lab_digit          ),

        .x             (   x                  ),
        .y             (   y                  ),

        .red           (   lab_red            ),
        .green         (   lab_green          ),
        .blue          (   lab_blue           ),

        .uart_rx       (   UART_RX            ),
        .uart_tx       (   UART_TX            ),

        .mic           (   mic                ),
        .sound         (   sound              ),

        .gpio          (   GPIO               )
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
            .sio_data ( GPIO [0]   ),  // GPIO1 pin 1
            .sio_clk  ( GPIO [1]   ),  // GPIO1 pin 2
            .sio_stb  ( GPIO [2]   )   // GPIO1 pin 3
        );
    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz  )
        )
        i_microphone
        (
            .clk     ( clk      ),
            .rst     ( rst      ),
            .lr      ( GPIO [4] ),  // GPIO1 pin 5
            .ws      ( GPIO [5] ),  // GPIO1 pin 6
            .sck     ( GPIO [6] ),  // GPIO1 pin 7
            .sd      ( GPIO [7] ),  // GPIO1 pin 8
            .value   ( mic      )
        );                          // GPIO1 pin 30 - GND, pin 29 - VCC 3.3V

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz     )
        )
        inst_audio_out
        (
            .clk     ( clk         ),
            .reset   ( rst         ),
            .data_in ( sound       ),
            .mclk    ( GPIO [9]    ), // GPIO1 pin 47
            .bclk    ( GPIO [10]   ), // GPIO1 pin 48
            .lrclk   ( GPIO [11]   ), // GPIO1 pin 49
            .sdata   ( GPIO [12]   )  // GPIO1 pin 50
        );                            // GPIO1 pin 30 - GND, pin 29 - VCC 3.3V

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        wire red_serial, green_serial, blue_serial;

        dvi_top i_dvi_top (
            .serial_clk_i   ( serial_clk   ),
            .pixel_clk_i    ( pixel_clk    ),
            .rst_i          ( rst          ),
            .red_i          ( red          ),
            .green_i        ( green        ),
            .blue_i         ( blue         ),
            .x_o            ( x10          ),
            .y_o            ( y10          ),
            .red_serial_o   ( red_serial   ),
            .green_serial_o ( green_serial ),
            .blue_serial_o  ( blue_serial  )
        );

        OBUFDS #(
            .IOSTANDARD ("DEFAULT"),
            .SLEW       ("SLOW"   )
        ) OBUFDS_blue (
            .O  (TMDS_D_P[0]  ),
            .OB (TMDS_D_N[0]  ),
            .I  (blue_serial  )
        );

        OBUFDS #(
            .IOSTANDARD ("DEFAULT"),
            .SLEW       ("SLOW"   )
        ) OBUFDS_green (
            .O  (TMDS_D_P[1]  ),
            .OB (TMDS_D_N[1]  ),
            .I  (green_serial )
        );

        OBUFDS #(
            .IOSTANDARD ("DEFAULT"),
            .SLEW       ("SLOW"   )
        ) OBUFDS_red (
            .O  (TMDS_D_P[2]  ),
            .OB (TMDS_D_N[2]  ),
            .I  (red_serial   )
        );

        OBUFDS #(
            .IOSTANDARD ("DEFAULT"),
            .SLEW       ("SLOW"   )
        ) OBUFDS_pixel_clk (
            .O  (TMDS_CLK_P   ),
            .OB (TMDS_CLK_N   ),
            .I  (pixel_clk    )
        );

    `endif

endmodule