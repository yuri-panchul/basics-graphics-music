`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 3,
              w_sw          = 10,  // One onboard SW is used as a reset
              w_led         = 10,
              w_digit       = 4,
              w_gpio        = 64,  // GPIO_0[7:2] reserved for mic

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                    CLOCK_50,

    input  [ w_key    - 1:0] BUTTON,
    input  [ w_sw     - 1:0] SW,
    output [ w_led    - 1:0] LEDG,

    output logic             HEX0_DP,
    output logic [      6:0] HEX0_D,
    output logic             HEX1_DP,
    output logic [      6:0] HEX1_D,
    output logic             HEX2_DP,
    output logic [      6:0] HEX2_D,
    output logic             HEX3_DP,
    output logic [      6:0] HEX3_D,

    output                   VGA_HS,
    output                   VGA_VS,
    output [ w_red    - 1:0] VGA_R,
    output [ w_green  - 1:0] VGA_G,
    output [ w_blue   - 1:0] VGA_B,

    input                    UART_RTS,
    input                    UART_RXD,

    output                   UART_CTS,
    output                   UART_TXD,

    inout  [          31:0]  GPIO0_D,
    inout  [          31:0]  GPIO1_D
);

    //------------------------------------------------------------------------

    localparam w_lab_sw = w_sw - 1;  // One onboard SW is used as a reset

    wire                   clk    = CLOCK_50;

    wire                   rst    = SW [w_lab_sw];
    wire [ w_lab_sw - 1:0] lab_sw = SW [w_lab_sw - 1:0];

    //------------------------------------------------------------------------

    // Seven-segment display

    wire [            7:0] abcdefgh;
    wire [ w_digit  - 1:0] digit;

    // Graphics

    wire                   display_on;

    wire [ w_x      - 1:0] x;
    wire [ w_y      - 1:0] y;

    wire [ w_red    - 1:0] red;
    wire [ w_green  - 1:0] green;
    wire [ w_blue   - 1:0] blue;

    assign VGA_R = display_on ? red   : '0;
    assign VGA_G = display_on ? green : '0;
    assign VGA_B = display_on ? blue  : '0;

    // Sound

    wire [           23:0] mic;
    wire [           15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz              ),
        .w_key         (   w_key                ),
        .w_sw          (   w_lab_sw             ),
        .w_led         (   w_led                ),
        .w_digit       (   w_digit              ),
        .w_gpio        (   w_gpio               ),  // GPIO_0[7:2] reserved for mic

        .screen_width  (   screen_width         ),
        .screen_height (   screen_height        ),

        .w_red         (   w_red                ),
        .w_green       (   w_green              ),
        .w_blue        (   w_blue               )
    )
    i_lab_top
    (
        .clk           (   clk                  ),
        .slow_clk      (   slow_clk             ),
        .rst           (   rst                  ),

        .key           ( ~ BUTTON               ),
        .sw            (   lab_sw               ),

        .led           (   LEDG                 ),

        .abcdefgh      (   abcdefgh             ),
        .digit         (   digit                ),

        .x             (   x                    ),
        .y             (   y                    ),

        .red           (   red                  ),
        .green         (   green                ),
        .blue          (   blue                 ),

        .mic           (   mic                  ),
        .sound         (   sound                ),

        .uart_rx       (   UART_RXD             ),
        .uart_tx       (   UART_TXD             ),

        .gpio          (   { GPIO0_D, GPIO1_D } )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.

        assign HEX0_D  = digit [0] ? ~ hgfedcba [$left (HEX0_D):0]   : '1;
        assign HEX0_DP = digit [0] ? ~ hgfedcba [$left (HEX0_D) + 1] : '1;
        assign HEX1_D  = digit [1] ? ~ hgfedcba [$left (HEX1_D):0]   : '1;
        assign HEX1_DP = digit [1] ? ~ hgfedcba [$left (HEX1_D) + 1] : '1;
        assign HEX2_D  = digit [2] ? ~ hgfedcba [$left (HEX2_D):0]   : '1;
        assign HEX2_DP = digit [2] ? ~ hgfedcba [$left (HEX2_D) + 1] : '1;
        assign HEX3_D  = digit [3] ? ~ hgfedcba [$left (HEX3_D):0]   : '1;
        assign HEX3_DP = digit [3] ? ~ hgfedcba [$left (HEX3_D) + 1] : '1;

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0_D, HEX0_DP, HEX1_D, HEX1_DP, HEX2_D, HEX2_DP, HEX3_D, HEX3_DP } <= '1;
            end
            else
            begin
                if (digit [0]) HEX0_D  <= ~ hgfedcba [$left (HEX0_D):0];
                if (digit [1]) HEX1_D  <= ~ hgfedcba [$left (HEX1_D):0];
                if (digit [2]) HEX2_D  <= ~ hgfedcba [$left (HEX2_D):0];
                if (digit [3]) HEX3_D  <= ~ hgfedcba [$left (HEX3_D):0];

                if (digit [0]) HEX0_DP <= ~ hgfedcba [$left (HEX0_D) + 1];
                if (digit [1]) HEX1_DP <= ~ hgfedcba [$left (HEX1_D) + 1];
                if (digit [2]) HEX2_DP <= ~ hgfedcba [$left (HEX2_D) + 1];
                if (digit [3]) HEX3_DP <= ~ hgfedcba [$left (HEX3_D) + 1];
            end

    `endif

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
            .clk_mhz ( clk_mhz  )
        )
        i_microphone
        (
            .clk   ( clk         ),
            .rst   ( rst         ),
            .lr    ( GPIO0_D [2] ), // JP4 pin 5
            .ws    ( GPIO0_D [4] ), // JP4 pin 7
            .sck   ( GPIO0_D [6] ), // JP4 pin 9
            .sd    ( GPIO0_D [7] ), // JP4 pin 10
            .value ( mic         )
        );

        assign GPIO0_D [3] = 1'b0;    // GND - JP4 pin 6
        assign GPIO0_D [5] = 1'b1;    // VCC - JP4 pin 8

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz     )
        )
        inst_audio_out
        (
            .clk     ( clk          ),
            .reset   ( rst          ),
            .data_in ( sound        ),
            .mclk    ( GPIO0_D [29] ), // JP4 pin 38
            .bclk    ( GPIO0_D [27] ), // JP4 pin 36
            .lrclk   ( GPIO0_D [23] ), // JP4 pin 32
            .sdata   ( GPIO0_D [25] )  // JP4 pin 34
        );                             // JP4 pin 30 - GND
                                       // JP4 pin 29 - VCC 3.3V (30-45 mA)

    `endif

endmodule
