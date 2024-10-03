`include "config.svh"
`include "lab_specific_board_config.svh"

`define USE_INTERNALLY_WIDE_COLOR_CHANNELS

// `define  COMPENSATE_DEFECTIVE_BOARD_WITH_DIGIT_0_NOT_WORKING

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 8,
              w_led         = 12,
              w_digit       = 8,
              w_gpio        = 19,

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

    input  [w_key   - 1:0] KEY_N,  // One key is used as a reset
    input  [w_sw    - 1:0] SW_N,
    output [w_led   - 1:0] LED_N,

    output [          7:0] ABCDEFGH_N,
    output [w_digit - 1:0] DIGIT_N,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output [          2:0] VGA_RGB,

    input                  UART_RX,
    output                 UART_TX,

    inout  [w_gpio  - 1:0] GPIO
);

    //------------------------------------------------------------------------

    localparam w_lab_key = w_key - 1;  // One onboard key is used as a reset

    wire                   clk     = CLK;
    wire                   rst     = ~ KEY_N [w_key     - 1];
    wire [w_lab_key - 1:0] lab_key = ~ KEY_N [w_lab_key - 1:0];

    //------------------------------------------------------------------------

    wire [w_led - 1:0] led;

    //------------------------------------------------------------------------

    `ifdef COMPENSATE_DEFECTIVE_BOARD_WITH_DIGIT_0_NOT_WORKING
        localparam w_lab_digit = w_digit - 1;
    `else
        localparam w_lab_digit = w_digit;
    `endif

    wire [              7:0] abcdefgh;
    wire [w_lab_digit - 1:0] lab_digit;

    //------------------------------------------------------------------------

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
        .w_digit       (   w_lab_digit   ),
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
        .sw            ( ~ SW_N          ),

        .led           (   led           ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   lab_digit     ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .uart_rx       (   UART_RX       ),
        .uart_tx       (   UART_TX       ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .gpio          (   GPIO          )
    );

    //------------------------------------------------------------------------

    assign LED_N       = ~ led;

    assign ABCDEFGH_N  = ~ abcdefgh;

    `ifdef COMPENSATE_DEFECTIVE_BOARD_WITH_DIGIT_0_NOT_WORKING
        assign DIGIT_N = ~ { lab_digit, 1'b0 };
    `else
        assign DIGIT_N = ~   lab_digit;
    `endif

    assign VGA_RGB     = display_on ? { | red, | green, | blue } : '0;

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
            .lr      ( GPIO [5] ),  // P33
            .ws      ( GPIO [3] ),  // P31
            .sck     ( GPIO [1] ),  // P28
            .sd      ( GPIO [0] ),  // P30
            .value   ( mic      )
        );

        assign GPIO [4] = 1'b0;  // P34 - GND
        assign GPIO [2] = 1'b1;  // P32 - VCC

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
            .mclk    ( GPIO [14] ),  // P52
            .bclk    ( GPIO [12] ),  // P49
            .lrclk   ( GPIO [ 8] ),  // P42
            .sdata   ( GPIO [10] )   // P44
        );                           // GND
                                     // J4 Pin 2 - VCC 3.3V (30-45 mA)
    `endif

endmodule
