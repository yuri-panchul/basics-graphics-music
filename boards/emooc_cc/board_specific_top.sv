// This board is referred as "MINI FPGA", EPI-MiniCY4
// and as a part of a kit called EPI-LITE304.
//
// See http://emooc.cc
// and http://www.emooc.cc/ProductDetail/1600208.html
// for more details.

`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 8,
              w_sw          = 8,
              w_led         = 16,
              w_digit       = 6,

              w_gpio        = 8,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   CLK,

    input  [w_key   - 1:0]  KEY,
    input  [w_sw    - 1:0]  SW,
    output [w_led   - 1:0]  LED,

    output [          7:0]  SEG,
    output [w_digit - 1:0]  DIG,

    input                   UART_RX,
    output                  UART_TX,

    output                  VGA_HSYNC,
    output                  VGA_VSYNC,
    output [w_red   - 1:0]  VGA_R,
    output [w_green - 1:0]  VGA_G,
    output [w_blue  - 1:0]  VGA_B,

    inout  [w_gpio - 1:0 ]  GPIO
);

    //------------------------------------------------------------------------

    wire                    clk;
    wire                    rst;

    wire [w_key    - 2:0]   lab_key;
    wire [w_led    - 1:0]   lab_led;


    // A dynamic seven-segment display

    wire [             7:0] abcdefgh;
    wire [ w_digit   - 1:0] digit;

    // Graphics
    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    // Microphone, sound output and UART

    wire [          23:0]   mic;
    wire [          15:0]   sound;

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

        .w_red         (   w_red         ),  // This is not true RGB channel width
        .w_green       (   w_green       ),
        .w_blue        (   w_blue        )
    )
    i_lab_top
    (
        .clk           (   clk           ),
        .slow_clk      (   slow_clk      ),
        .rst           (   rst           ),

        .key           ( ~ lab_key       ),
        .sw            ( ~ SW            ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   VGA_R         ),
        .green         (   VGA_G         ),
        .blue          (   VGA_B         ),

        .uart_rx       (   UART_RX       ),
        .uart_tx       (   UART_TX       ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .gpio          (   GPIO          )
    );

    //------------------------------------------------------------------------

    assign clk       =   CLK;

    assign LED       = ~ lab_led;

    assign SEG       =   abcdefgh;
    assign DIG       = ~ digit;

    assign rst       = ~ KEY [w_key - 1  ];
    assign lab_key   =   KEY [w_key - 2:0];

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
            .clk         ( clk          ),
            .rst         ( rst          ),
            .hsync       ( VGA_HSYNC    ),
            .vsync       ( VGA_VSYNC    ),
            .display_on  (              ),
            .hpos        ( x10          ),
            .vpos        ( y10          ),
            .pixel_clk   (              )
        );

    `endif

 //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz   )
        )
        i_microphone
        (
            .clk     ( clk       ),
            .rst     ( rst       ),
            .lr      ( GPIO[0]   ),  // PIN_B13
            .ws      ( GPIO[1]   ),  // PIN_A14
            .sck     ( GPIO[2]   ),  // PIN_B14
            .sd      ( GPIO[3]   ),  // PIN_A15
            .value   ( mic       )
        );

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
            .mclk    ( GPIO [4]  ),  // PIN_N6 
            .bclk    ( GPIO [5]  ),  // PIN_R8
            .lrclk   ( GPIO [6]  ),  // PIN_T8
            .sdata   ( GPIO [7]  )   // PIN_T9
        );

    `endif

    //------------------------------------------------------------------------

endmodule
