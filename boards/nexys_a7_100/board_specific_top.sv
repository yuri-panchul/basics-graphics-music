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
    input                   CLK100MHZ,
    input                   CPU_RESETN,

    input                   BTNC,
    input                   BTNU,
    input                   BTNL,
    input                   BTNR,
    input                   BTND,

    input  [w_sw     - 1:0] SW,
    output [w_led    - 1:0] LED,

    output                  LED16_B,
    output                  LED16_G,
    output                  LED16_R,

    output                  LED17_B,
    output                  LED17_G,
    output                  LED17_R,

    output                  CA,
    output                  CB,
    output                  CC,
    output                  CD,
    output                  CE,
    output                  CF,
    output                  CG,

    output                  DP,

    output [w_digit  - 1:0] AN,

    output [w_red    - 1:0] VGA_R,
    output [w_blue   - 1:0] VGA_G,
    output [w_green  - 1:0] VGA_B,

    output                  VGA_HS,
    output                  VGA_VS,

    input                   UART_TXD_IN,
    output                  UART_RXD_OUT,

    inout            [12:1] JA,
    inout            [12:1] JB,
    inout            [12:1] JC,
    inout            [12:1] JD,

    output                  M_CLK,
    input                   M_DATA,
    output                  M_LRSEL,

    output                  AUD_PWM,
    output                  AUD_SD
);

    //------------------------------------------------------------------------

    wire clk =   CLK100MHZ;
    wire rst = ~ CPU_RESETN;

    //------------------------------------------------------------------------

    assign LED16_B = 1'b0;
    assign LED16_G = 1'b0;
    assign LED16_R = 1'b0;
    assign LED17_B = 1'b0;
    assign LED17_G = 1'b0;
    assign LED17_R = 1'b0;

    assign M_CLK   = 1'b0;
    assign M_LRSEL = 1'b0;

    //assign AUD_PWM = 1'b0;
    assign AUD_SD  = 1'b1;

    //------------------------------------------------------------------------

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    assign { CA, CB, CC, CD, CE, CF, CG, DP } = ~ abcdefgh;
    assign AN = ~ digit;

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    assign VGA_R = display_on ? red   : '0;
    assign VGA_G = display_on ? green : '0;
    assign VGA_B = display_on ? blue  : '0;

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

        .key           ( { BTND, BTNU, BTNL, BTNC, BTNR } ),
        .sw            ( SW             ),

        .led           ( LED            ),

        .abcdefgh      ( abcdefgh       ),
        .digit         ( digit          ),

        .x             ( x              ),
        .y             ( y              ),

        .red           ( red            ),
        .green         ( green          ),
        .blue          ( blue           ),

        .mic           ( mic            ),
        .sound         ( sound          ),

        .uart_rx       ( UART_TXD_IN    ),
        .uart_tx       ( UART_RXD_OUT   ),

        .gpio          (                )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz     ),
            .PIXEL_MHZ   ( pixel_mhz   )
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( VGA_HS     ),
            .vsync       ( VGA_VS     ),
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
            .clk     ( clk     ),
            .rst     ( rst     ),
            .lr      ( JD [9]  ),
            .ws      ( JD [8]  ),
            .sck     ( JD [7]  ),
            .sd      ( JD [1]  ),
            .value   ( mic     )
        );

        assign JD [3] = 1'b0;  // GND
        assign JD [2] = 1'b1;  // VCC

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

            .mclk    ( JC [ 7]  ),
            .bclk    ( JC [ 8]  ),
            .sdata   ( JC [ 9]  ),
            .lrclk   ( JC [10]  )
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

            .mclk    ( JB [9]  ),
            .bclk    ( JB [4]  ),
            .sdata   ( JB [2]  ),
            .lrclk   ( JB [1]  )
        );

        logic sound_pwm;

        audio_pwm
        # (
            .data_w (8)
        )
        inst_nexys_pwm
        (
            .clk_i  ( clk     ),
            .rst_i  ( rst     ),

            .data_i ( sound [15:8]  ),
            .pwm_o  ( sound_pwm )
        );

        // Actual audio output driver ( from board datasheet: 1'b0 for 0 V and HighZ for 3.3 V )
        assign AUD_PWM = (sound_pwm) ? 'Z : '0;

    `endif

endmodule
