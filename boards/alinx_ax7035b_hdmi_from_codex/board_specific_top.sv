`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

`ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
`undef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
`endif

`ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
`undef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
`endif

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 0,
              w_led         = 4,
              w_digit       = 6,
              w_gpio        = 68,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   sys_clk,
    input                   rst_n,

    input  [w_key    - 1:0] key_in,
    output [w_led    - 1:0] led,

    output [           7:0] SMG_Data,
    output [w_digit  - 1:0] Scan_Sig,

    output                  TMDS_clk_n,
    output                  TMDS_clk_p,
    output [           2:0] TMDS_data_n,
    output [           2:0] TMDS_data_p,
    output [           0:0] HDMI_OEN,

    input                   uart_rx,
    output                  uart_tx

    // TODO
    // inout [3:36] j9,
    // inout [3:36] j10
);

    // TODO

    wire [3:36] j9;
    wire [3:36] j10;

    //------------------------------------------------------------------------

    // Clock and reset

    wire clk;
    wire rst;

    // Keys and LEDs

    wire [w_key - 1:0] lab_key;
    wire [w_led - 1:0] lab_led;

    `SWAP_BITS ( lab_key , ~ key_in  );
    `SWAP_BITS ( led     , ~ lab_led );

    // Seven-segment display

    wire [7:0] abcdefgh;
    wire [7:0] digit;

    `SWAP_BITS (SMG_Data, ~ abcdefgh);
    assign Scan_Sig = ~ digit;

    // Graphics

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    // Sound

    wire [         23:0] mic;
    wire [         15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz        ),
        .w_key         ( w_key          ),
        .w_sw          ( w_key          ),
        .w_led         ( w_led          ),
        .w_digit       ( w_digit        ),
        .w_gpio        ( w_gpio         ),

        .screen_width  ( screen_width   ),
        .screen_height ( screen_height  ),

        .w_red         ( w_red          ),
        .w_green       ( w_green        ),
        .w_blue        ( w_blue         )
    )
    i_lab_top
    (
        .clk           ( clk            ),
        .slow_clk      ( slow_clk       ),
        .rst           ( rst            ),

        .key           ( lab_key        ),
        .sw            ( lab_key        ),

        .led           ( lab_led        ),

        .abcdefgh      ( abcdefgh       ),
        .digit         ( digit          ),

        .x             ( x              ),
        .y             ( y              ),

        .red           ( red            ),
        .green         ( green          ),
        .blue          ( blue           ),

        .mic           ( mic            ),
        .sound         ( sound          ),

        .uart_rx       ( uart_rx        ),
        .uart_tx       ( uart_tx        ),

        .gpio          ( { j9, j10 }    )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        // 50 MHz lab clock, 25 MHz pixels, 640x480 DVI video over HDMI1.
        ax7035b_hdmi i_hdmi
        (
            .clk_in      ( sys_clk     ),
            .rst_in      ( ~ rst_n     ),
            .clk         ( clk         ),
            .rst         ( rst         ),
            .x           ( x           ),
            .y           ( y           ),
            .red         ( red         ),
            .green       ( green       ),
            .blue        ( blue        ),
            .tmds_clk_p  ( TMDS_clk_p  ),
            .tmds_clk_n  ( TMDS_clk_n  ),
            .tmds_data_p ( TMDS_data_p ),
            .tmds_data_n ( TMDS_data_n ),
            .hdmi_enable ( HDMI_OEN[0] )
        );

    `else

        assign clk = sys_clk;
        assign rst = ~ rst_n;
        assign x = '0;
        assign y = '0;
        assign HDMI_OEN = '0;

        // Keep the HDMI outputs differential even in non-graphics labs.
        OBUFDS # (.IOSTANDARD ("TMDS_33")) i_idle_clock
            (.I (1'b0), .O (TMDS_clk_p), .OB (TMDS_clk_n));

        for (genvar lane = 0; lane < 3; lane++)
        begin : g_idle_data
            OBUFDS # (.IOSTANDARD ("TMDS_33")) i_idle_data
                (.I (1'b0), .O (TMDS_data_p[lane]), .OB (TMDS_data_n[lane]));
        end

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz )
         )
        i_microphone
        (
            .clk     ( clk    ),
            .rst     ( rst    ),
            .lr      ( JA [6] ),
            .ws      ( JA [5] ),
            .sck     ( JA [4] ),
            .sd      ( JA [0] ),
            .value   ( mic    )
        );

        assign JA [2] = 1'b0;  // GND - JA pin 3
        assign JA [1] = 1'b1;  // VCC - JA pin 2

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz )
        )
        inst_pcm5102
        (
            .clk     ( clk     ),
            .reset   ( rst     ),
            .data_in ( sound   ),

            .mclk    ( JC [4]  ),
            .bclk    ( JC [5]  ),
            .sdata   ( JC [6]  ),
            .lrclk   ( JC [7]  )
        );

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz )
        )
        inst_pmod_amp3
        (
            .clk     ( clk     ),
            .reset   ( rst     ),
            .data_in ( sound   ),

            .mclk    ( JB [6]  ),
            .bclk    ( JB [3]  ),
            .sdata   ( JB [1]  ),
            .lrclk   ( JB [0]  )
        );

    `endif

endmodule
