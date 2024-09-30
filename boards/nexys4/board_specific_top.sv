`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 100,
              pixel_mhz     = 25,

              w_key         = 5,
              w_sw          = 16,
              w_led         = 16,
              w_digit       = 8,
              w_gpio        = 32,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   clk,
    input                   btnCpuReset,

    input                   btnC,
    input                   btnU,
    input                   btnL,
    input                   btnR,
    input                   btnD,

    input  [w_sw     - 1:0] sw,
    output [w_led    - 1:0] led,

    output                  RGB1_Red,
    output                  RGB1_Green,
    output                  RGB1_Blue,

    output                  RGB2_Red,
    output                  RGB2_Green,
    output                  RGB2_Blue,

    output [           6:0] seg,
    output                  dp,
    output [w_digit  - 1:0] an,

    output                  Hsync,
    output                  Vsync,

    output [w_red    - 1:0] vgaRed,
    output [w_blue   - 1:0] vgaBlue,
    output [w_green  - 1:0] vgaGreen,

    input                   RsRx,

    inout  [           7:0] JA,
    inout  [           7:0] JB,
    inout  [           7:0] JC,
    inout  [           7:0] JD,

    output                  micClk,
    input                   micData,
    output                  micLRSel,

    output                  ampPWM,
    output                  ampSD
);

    //------------------------------------------------------------------------

    wire rst = ~ btnCpuReset;

    //------------------------------------------------------------------------

    assign RGB1_Red   = 1'b0;
    assign RGB1_Green = 1'b0;
    assign RGB1_Blue  = 1'b0;

    assign RGB2_Red   = 1'b0;
    assign RGB2_Green = 1'b0;
    assign RGB2_Blue  = 1'b0;

    assign micClk     = 1'b0;
    assign micLRSel   = 1'b0;

    assign ampPWM     = 1'b0;
    assign ampSD      = 1'b0;

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    assign { seg [0], seg [1], seg [2], seg [3],
             seg [4], seg [5], seg [6], dp       } = ~ abcdefgh;

    assign an = ~ digit;

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    assign vgaRed   = display_on ? red   : '0;
    assign vgaBlue  = display_on ? green : '0;
    assign vgaGreen = display_on ? blue  : '0;

    wire [     23:0] mic;
    wire [     15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz        ),
        .w_key         ( w_key          ),
        .w_sw          ( w_sw           ),
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

        .key           ( { btnD, btnU, btnL, btnC, btnR } ),
        .sw            ( sw             ),

        .led           ( led            ),

        .abcdefgh      ( abcdefgh       ),
        .digit         ( digit          ),

        .x             ( x              ),
        .y             ( y              ),

        .red           ( red            ),
        .green         ( green          ),
        .blue          ( blue           ),

        .mic           ( mic            ),
        .sound         ( sound          ),

        .uart_rx       ( RsRx           ),
        .uart_tx       (                ),

        .gpio          (                )
    );

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
            .hsync       ( Hsync      ),
            .vsync       ( Vsync      ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

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
            .lr      ( JD [6] ),
            .ws      ( JD [5] ),
            .sck     ( JD [4] ),
            .sd      ( JD [0] ),
            .value   ( mic    )
        );

        assign JD [2] = 1'b0;  // GND - JD pin 3
        assign JD [1] = 1'b1;  // VCC - JD pin 2

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
