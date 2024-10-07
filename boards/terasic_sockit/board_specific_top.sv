`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 4,
              w_led         = 4,
              w_digit       = 0,
              w_gpio        = 0,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                  OSC_50_B3B,
    input                  RESET_n,

    input  [w_key   - 1:0] KEY,
    input  [w_sw    - 1:0] SW,
    output [w_led   - 1:0] LED,

    output [w_red   - 1:0] VGA_R,
    output [w_green - 1:0] VGA_G,
    output [w_blue  - 1:0] VGA_B,

    output                 VGA_CLK,
    output                 VGA_HS,
    output                 VGA_VS,
    output                 VGA_BLANK_n,
    output                 VGA_SYNC_n
);

    //------------------------------------------------------------------------

    wire clk = OSC_50_B3B;
    wire rst = ~ RESET_n;

    //------------------------------------------------------------------------

    // Graphics

    wire [w_x - 1:0] x;
    wire [w_y - 1:0] y;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz         ),
        .w_key         ( w_key           ),
        .w_sw          ( w_sw            ),
        .w_led         ( w_led           ),
        .w_digit       ( 1 /* w_digit */ ),
        .w_gpio        ( 1 /* w_gpio  */ ),

        .screen_width  ( screen_width    ),
        .screen_height ( screen_height   ),

        .w_red         ( w_red           ),
        .w_green       ( w_green         ),
        .w_blue        ( w_blue          )
    )
    i_lab_top
    (
        .clk           (   clk           ),
        .slow_clk      (   slow_clk      ),
        .rst           (   rst           ),

        .key           ( ~ KEY           ),
        .sw            (   SW            ),

        .led           (   LED           ),

        .abcdefgh      (                 ),
        .digit         (                 ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   VGA_R         ),
        .green         (   VGA_G         ),
        .blue          (   VGA_B         ),

        .mic           (                 ),
        .sound         (                 ),

        .uart_rx       (                 ),
        .uart_tx       (                 ),

        .gpio          (                 )
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
            .clk         ( clk         ),
            .rst         ( rst         ),
            .hsync       ( VGA_HS      ),
            .vsync       ( VGA_VS      ),
            .display_on  ( VGA_BLANK_n ),
            .hpos        ( x10         ),
            .vpos        ( y10         ),
            .pixel_clk   ( VGA_CLK     )
        );

        assign VGA_SYNC_n  = 1'b0;

    `endif

endmodule
