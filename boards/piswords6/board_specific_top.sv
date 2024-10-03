`include "config.svh"
`include "lab_specific_board_config.svh"

`define USE_INTERNALLY_WIDE_COLOR_CHANNELS

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 4,
              w_led         = 8,
              w_digit       = 8,
              w_gpio        = 16,

              screen_width  = 640,
              screen_height = 480,

              `ifdef USE_INTERNALLY_WIDE_COLOR_CHANNELS

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              `else

              w_red         = 1,
              w_green       = 1,
              w_blue        = 1,

              `endif

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                  CLK,

    input  [w_key   - 1:0] KEY,
    input  [w_sw    - 1:0] SW,
    output [w_led   - 1:0] LED,

    output [          7:0] ABCDEFGH,
    output [w_digit - 1:0] DIGIT,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output [          2:0] VGA_RGB,

    input                  UART_RXD,
    output                 UART_TXD,

    inout  [w_gpio  - 1:0] GPIO
);

    //------------------------------------------------------------------------

    wire clk = CLK;

    localparam w_lab_key = w_key - 1;  // One key is used as a reset

    wire                   rst     = ~ KEY [w_lab_key];
    wire [w_lab_key - 1:0] lab_key = ~ KEY [w_lab_key - 1:0];

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;

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
        .clk_mhz       (   clk_mhz       ),
        .w_key         (   w_lab_key     ),
        .w_sw          (   w_sw          ),
        .w_led         (   w_led         ),
        .w_digit       (   w_digit       ),
        .w_gpio        (   w_gpio        ),

        .screen_width  (   screen_width  ),
        .screen_height (   screen_height ),

        .w_red         (   w_red         ),
        .w_green       (   w_green       ),
        .w_blue        (   w_blue        )
    )
    i_lab_top
    (
        .clk           (   clk           ),
        .slow_clk      (   slow_clk      ),
        .rst           (   rst           ),

        .key           (   lab_key       ),
        .sw            ( ~ SW            ),

        .led           (   led           ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .uart_rx       (   UART_RXD      ),
        .uart_tx       (   UART_TXD      ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .gpio          (   GPIO          )

    );

    //------------------------------------------------------------------------

    assign LED      = ~ led;

    assign ABCDEFGH = ~ abcdefgh;
    assign DIGIT    = ~ digit;

    assign VGA_RGB  = display_on ? { | red, | green, | blue } : '0;

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
            .hsync       ( VGA_HSYNC  ),
            .vsync       ( VGA_VSYNC  ),
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
            .clk_mhz ( clk_mhz  )
        )
        i_microphone
        (
            .clk     ( clk      ),
            .rst     ( rst      ),
            .lr      ( GPIO [0] ),  // 144
            .ws      ( GPIO [2] ),  // 142
            .sck     ( GPIO [4] ),  // 138
            .sd      ( GPIO [5] ),  // 137
            .value   ( mic      )
        );

        assign GPIO [1] = 1'b0;     // 143
        assign GPIO [3] = 1'b1;     // 141

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz   )
        )
        inst_audio_out
        (
            .clk     ( clk       ),
            .reset   ( rst       ),
            .data_in ( sound     ),
            .mclk    ( GPIO [12] ),  // 127 : PCM5102A : SCK
            .bclk    ( GPIO [10] ),  // 129 : PCM5102A : BCK
            .lrclk   ( GPIO [ 6] ),  // 136 : PCM5102A : LCK
            .sdata   ( GPIO [ 8] )   // 133 : PCM5102A : DIN
        );                           // GND
                                     // VCC 3.3V (30-45 mA) on dedicated pins
    `endif

endmodule
