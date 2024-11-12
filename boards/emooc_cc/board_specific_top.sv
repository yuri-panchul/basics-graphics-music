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
              w_y           = $clog2 ( screen_height ),

              w_gpio_j7     = 36,
              w_gpio_p1     = 21,
              w_gpio_p2     = 21
)
(
    input                        CLK,

    input  [w_key         - 1:0] KEY_N,
    input  [w_sw          - 1:0] SW,

    output [w_led         - 1:0] LED,

    output [                7:0] ABCDEFGH,
    output [w_digit       - 1:0] DIGIT_N,

    input                        UART_RX,
    output                       UART_TX,

    inout  [w_gpio_j7 + 3 - 1:3] GPIO_J7,
    inout  [w_gpio_p1 + 2 - 1:2] GPIO_P1,
    inout  [w_gpio_p2 + 2 - 1:2] GPIO_P2
);

    //------------------------------------------------------------------------

    wire                    clk;
    wire                    rst;

    wire [w_key    - 2:0]   lab_key;
    wire [w_led    - 1:0]   lab_led;

    wire [w_gpio   - 1:0]   lab_gpio;


    // A dynamic seven-segment display

    wire [             7:0] abcdefgh;
    wire [ w_digit   - 1:0] digit;

    // Graphics
    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    // VGA
    wire                    vga_hsync;
    wire                    vga_vsync;

    wire [ w_red     - 1:0] vga_red;
    wire [ w_green   - 1:0] vga_green;
    wire [ w_blue    - 1:0] vga_blue;

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

        .key           (   lab_key       ),
        .sw            ( ~ SW            ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   vga_red       ),
        .green         (   vga_green     ),
        .blue          (   vga_blue      ),

        .uart_rx       (   UART_RX       ),
        .uart_tx       (   UART_TX       ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .gpio          (   lab_gpio      )
    );

    //------------------------------------------------------------------------

    assign clk       =   CLK;

    assign LED       = ~ lab_led;

    assign ABCDEFGH  =   abcdefgh;
    assign DIGIT_N   = ~ digit;

    assign rst       = ~ KEY_N [w_key - 1  ];
    assign lab_key   = ~ KEY_N [w_key - 2:0];

    assign GPIO_P1 [2]       = vga_hsync;  // PIN_C6
    assign GPIO_P1 [3]       = vga_vsync;  // PIN_B6

    assign GPIO_P1 [7  :  4] = vga_red  ;  // PIN_B8, A7, B7, A6
    assign GPIO_P1 [11 :  8] = vga_green;  // PIN_A11, B9, A9, A8
    assign GPIO_P1 [15 : 12] = vga_blue ;  // PIN_A13, B12, A12, B11

    assign GPIO_P2 [14 :  6] = lab_gpio;   //

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
            .clk         ( clk       ),
            .rst         ( rst       ),
            .hsync       ( vga_hsync ),
            .vsync       ( vga_vsync ),
            .display_on  (           ),
            .hpos        ( x10       ),
            .vpos        ( y10       ),
            .pixel_clk   (           )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz      )
        )
        i_microphone
        (
            .clk     ( clk          ),
            .rst     ( rst          ),
            .lr      ( GPIO_P1 [16] ),  // PIN_B13
            .ws      ( GPIO_P1 [17] ),  // PIN_A14
            .sck     ( GPIO_P1 [18] ),  // PIN_B14
            .sd      ( GPIO_P1 [19] ),  // PIN_A15
            .value   ( mic          )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz      )
        )
        inst_audio_out
        (
            .clk     ( clk          ),
            .reset   ( rst          ),
            .data_in ( sound        ),
            .mclk    ( GPIO_P2 [2]  ),  // PIN_N6 on FPGA // SCK on sound card
            .bclk    ( GPIO_P2 [3]  ),  // PIN_R8 on FPGA // BCK on sound card
            .lrclk   ( GPIO_P2 [4]  ),  // PIN_T8 on FPGA // LCK on sound card
            .sdata   ( GPIO_P2 [5]  )   // PIN_T9 on FPGA // DIN on sound card
        );

    `endif

endmodule
