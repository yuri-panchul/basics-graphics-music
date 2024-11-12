`include "config.svh"
`include "lab_specific_board_config.svh"

`define USE_LCD_AS_GPIO
`define USE_INTERNALLY_WIDE_COLOR_CHANNELS

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 6,
              w_sw          = 4,
              w_led         = 8,
              w_digit       = 8,

              `ifdef USE_LCD_AS_GPIO
              w_gpio        = 11,
              `else
              w_gpio        = 1,
              `endif

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
    input         CLK,
    input         RST_N,

    input  [ 6:1] KEY,
    input  [ 4:1] CKEY,

    output [ 8:1] LED,

    output [ 7:0] DIG,
    output [ 0:7] SEG,

    input         RXD,
    output        TXD,

    output        VGA_HSYNC,
    output        VGA_VSYNC,

    output        VGA_R,
    output        VGA_G,
    output        VGA_B,

    inout  [11:1] LCD
);

    //------------------------------------------------------------------------

    wire clk =   CLK;
    wire rst = ~ RST_N;

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] lab_led;

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

    assign VGA_R = display_on & ( | red   );
    assign VGA_G = display_on & ( | green );
    assign VGA_B = display_on & ( | blue  );

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

        .w_key         (   w_key         ),
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

        .key           ( ~ KEY           ),
        .sw            ( ~ CKEY          ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .uart_rx       (   RXD           ),
        .uart_tx       (   TXD           ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        `ifdef USE_LCD_AS_GPIO
        .gpio          (   LCD           )
        `else
        .gpio          (                 )
        `endif
    );

    //------------------------------------------------------------------------

    assign LED       = ~ lab_led;

    assign SEG       = ~ abcdefgh;
    assign DIG       = ~ digit;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz   ),
            .PIXEL_MHZ   ( pixel_mhz )
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

        // TODO using LCD pins

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz )
        )
        i_microphone
        (
            .clk     ( clk     ),
            .rst     ( rst     ),
            .lr      (         ),
            .ws      (         ),
            .sck     (         ),
            .sd      (         ),
            .value   ( mic     )
        );

        // assign TODO = 1'b0;  // GND
        // assign TODO = 1'b1;  // VCC

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        // TODO using LCD pins

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz )
        )
        inst_audio_out
        (
            .clk     ( clk     ),
            .reset   ( rst     ),
            .data_in ( sound   ),
            .mclk    (         ),
            .bclk    (         ),
            .lrclk   (         ),
            .sdata   (         )
        );                         // GND and VCC 3.3V (30-45 mA)

    `endif

endmodule
