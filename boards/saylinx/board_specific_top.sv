`include "config.svh"
`include "lab_specific_board_config.svh"

// `define USE_DIGILENT_PMOD_MIC3

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 3,
              w_sw          = 0,
              w_led         = 4,

              `ifdef ALINX_AX4010
              w_digit       = 6,
              `else
              w_digit       = 8,
              `endif

              w_gpio        = 34 * 2,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                     CLK,
    input                     RST_N,

    input                     KEY2,
    input                     KEY3,
    input                     KEY4,

    output [w_led      - 1:0] LED,

    output [             7:0] SEG_DATA,
    output [w_digit    - 1:0] SEG_SEL,

    output                    VGA_OUT_HS,
    output                    VGA_OUT_VS,

    output [w_red      - 1:0] VGA_OUT_R,
    output [w_green    - 1:0] VGA_OUT_G,
    output [w_blue     - 1:0] VGA_OUT_B,

    input                     UART_RXD,
    output                    UART_TXD,

    inout  [w_gpio / 2 - 1:0] GPIO_0,
    inout  [w_gpio / 2 - 1:0] GPIO_1
);

    //------------------------------------------------------------------------

    wire                 clk = CLK;
    wire                 rst = ~ RST_N;

    wire [w_key   - 1:0] key = ~ { KEY2, KEY3, KEY4 };

    // Seven-segment display

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    // Graphics

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    assign VGA_OUT_R = display_on ? red   : '0;
    assign VGA_OUT_G = display_on ? green : '0;
    assign VGA_OUT_B = display_on ? blue  : '0;

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
        .clk_mhz       (   clk_mhz          ),

        .w_key         (   w_key            ),
        .w_sw          (   w_key            ),
        .w_led         (   w_led            ),
        .w_digit       (   w_digit          ),
        .w_gpio        (   w_gpio           ),

        .screen_width  (   screen_width     ),
        .screen_height (   screen_height    ),

        .w_red         (   w_red            ),
        .w_green       (   w_green          ),
        .w_blue        (   w_blue           )
    )
    i_lab_top
    (
        .clk           (   clk              ),
        .slow_clk      (   slow_clk         ),
        .rst           (   rst              ),

        .key           (   key              ),
        .sw            (   key              ),

        .led           (   LED              ),

        .abcdefgh      (   abcdefgh         ),
        .digit         (   digit            ),

        .x             (   x                ),
        .y             (   y                ),

        .red           (   red              ),
        .green         (   green            ),
        .blue          (   blue             ),

        .uart_rx       (   UART_RXD         ),
        .uart_tx       (   UART_TXD         ),

        .mic           (   mic              ),
        .sound         (   sound            ),

        .gpio          ( { GPIO_0, GPIO_1 } )
    );

    //------------------------------------------------------------------------

    assign SEG_DATA  = ~ abcdefgh;
    assign SEG_SEL   = ~ digit;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz    ),
            .PIXEL_MHZ   ( pixel_mhz  )
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( VGA_OUT_HS ),
            .vsync       ( VGA_OUT_VS ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        `ifdef USE_DIGILENT_PMOD_MIC3

            wire [11:0] mic_12;

            digilent_pmod_mic3_spi_receiver i_microphone
            (
                .clk   ( clk         ),
                .rst   ( rst         ),
                .cs    ( GPIO_1 [26] ), // C6
                .sck   ( GPIO_1 [32] ), // E9
                .sdo   ( GPIO_1 [30] ), // D8
                .value ( mic_12      )
            );

            wire [11:0] mic_12_minus_offset = mic_12 - 12'h800;
            assign mic = { { 12 { mic_12_minus_offset [11] } }, mic_12_minus_offset };

        `else

            inmp441_mic_i2s_receiver
            # (
                .clk_mhz ( clk_mhz    )
            )
            i_microphone
            (
                .clk     ( clk        ),
                .rst     ( rst        ),
                .lr      ( GPIO_0 [0] ), // N2
                .ws      ( GPIO_0 [2] ), // P2
                .sck     ( GPIO_0 [4] ), // P8
                .sd      ( GPIO_0 [5] ), // K9
                .value   ( mic        )
            );

            assign GPIO_0 [1] = 1'b0;  // GND - P1
            assign GPIO_0 [3] = 1'b1;  // VCC - R1

        `endif

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
            .mclk    ( GPIO_0 [12] ), // R3 PCM5102: SCK
            .bclk    ( GPIO_0 [10] ), // P3 PCM5102: BCK
            .lrclk   ( GPIO_0 [ 6] ), // L9 PCM5102: LCK
            .sdata   ( GPIO_0 [ 8] )  // M9 PCM5102: DIN
        );                            // 3.3V, GND on dedicated pins

    `endif

endmodule
