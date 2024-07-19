`include "config.svh"
`include "lab_specific_config.svh"

`define USE_HIGH_LED_FOR_7SEG_DP

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 18,
              w_led         = 18,
              w_digit       = 8,
              w_gpio        = 36,

              // gpio 0..5 are reserved for INMP 441 I2S microphone.
              // Odd gpio .. are reserved I2S audio.

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   CLOCK_50,

    input  [w_key    - 1:0] KEY,
    input  [w_sw     - 1:0] SW,
    output [w_led    - 1:0] LEDR,  // The last 8 LEDR are optionally used to output 7SEG dp

    output logic [     6:0] HEX0,  // HEX[7] aka dp are not connected to FPGA at DE2-115
    output logic [     6:0] HEX1,
    output logic [     6:0] HEX2,
    output logic [     6:0] HEX3,
    output logic [     6:0] HEX4,
    output logic [     6:0] HEX5,
    output logic [     6:0] HEX6,
    output logic [     6:0] HEX7,

    output                  VGA_CLK,
    output                  VGA_HS,
    output                  VGA_VS,
    output [w_red    - 1:0] VGA_R,
    output [w_green  - 1:0] VGA_G,
    output [w_blue   - 1:0] VGA_B,
    output                  VGA_BLANK_N,
    output                  VGA_SYNC_N,

    inout  [w_gpio   - 1:0] GPIO
);

    //------------------------------------------------------------------------

    localparam w_lab_sw = w_sw - 1;                // One sw is used as a reset

    `ifdef USE_HIGH_LED_FOR_7SEG_DP
        localparam w_lab_led = w_led - w_digit;
    `else
        localparam w_lab_led = w_led;
    `endif

    //------------------------------------------------------------------------

    wire                    clk     = CLOCK_50;
    wire                    rst     = SW [w_lab_sw];

    // Keys, switches, LEDs

    wire [ w_lab_sw  - 1:0] lab_sw  = SW [w_lab_sw - 1:0];
    wire [ w_key     - 1:0] lab_key = ~ KEY;
    wire [ w_lab_led - 1:0] lab_led;

    // A dynamic seven-segment display

    wire [             7:0] abcdefgh;
    wire [ w_digit   - 1:0] digit;

    // Graphics

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;

    // Microphone, sound output and UART

    wire [            23:0] mic;
    wire [            15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),
        .w_key         ( w_key         ),
        .w_sw          ( w_lab_sw      ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_digit       ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_sw        ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( digit         ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( VGA_R         ),
        .green         ( VGA_G         ),
        .blue          ( VGA_B         ),

        .mic           ( mic           ),
        .sound         ( sound         ),

        .uart_rx       (               ),  // TODO
        .uart_tx       (               ),  // TODO

        .gpio          ( GPIO          )
    );

    //------------------------------------------------------------------------

    assign LEDR [w_lab_led - 1:0] = lab_led;

    //------------------------------------------------------------------------

    wire  [$left ( abcdefgh ):0] hgfedcba;
    logic [$left ( digit    ):0] dp;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.

        // inverted logic

        assign HEX0 = digit [0] ? ~ hgfedcba [$left (HEX0):0] : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba [$left (HEX1):0] : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba [$left (HEX2):0] : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba [$left (HEX3):0] : '1;
        assign HEX4 = digit [4] ? ~ hgfedcba [$left (HEX4):0] : '1;
        assign HEX5 = digit [5] ? ~ hgfedcba [$left (HEX5):0] : '1;
        assign HEX6 = digit [6] ? ~ hgfedcba [$left (HEX6):0] : '1;
        assign HEX7 = digit [7] ? ~ hgfedcba [$left (HEX7):0] : '1;

        // positive logic

        assign LEDR [    w_led - w_digit] = digit [0] ? hgfedcba [$left (HEX0) + 1] : '0;
        assign LEDR [w_led - w_digit + 1] = digit [1] ? hgfedcba [$left (HEX1) + 1] : '0;
        assign LEDR [w_led - w_digit + 2] = digit [2] ? hgfedcba [$left (HEX2) + 1] : '0;
        assign LEDR [w_led - w_digit + 3] = digit [3] ? hgfedcba [$left (HEX3) + 1] : '0;
        assign LEDR [w_led - w_digit + 4] = digit [4] ? hgfedcba [$left (HEX4) + 1] : '0;
        assign LEDR [w_led - w_digit + 5] = digit [5] ? hgfedcba [$left (HEX5) + 1] : '0;
        assign LEDR [w_led - w_digit + 6] = digit [6] ? hgfedcba [$left (HEX6) + 1] : '0;
        assign LEDR [w_led - w_digit + 7] = digit [7] ? hgfedcba [$left (HEX7) + 1] : '0;

    `else

        always_ff @ (posedge clk or posedge rst)
        begin
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 } <= '1;
                dp <= '0;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba [$left (HEX0):0];
                if (digit [1]) HEX1 <= ~ hgfedcba [$left (HEX1):0];
                if (digit [2]) HEX2 <= ~ hgfedcba [$left (HEX2):0];
                if (digit [3]) HEX3 <= ~ hgfedcba [$left (HEX3):0];
                if (digit [4]) HEX4 <= ~ hgfedcba [$left (HEX4):0];
                if (digit [5]) HEX5 <= ~ hgfedcba [$left (HEX5):0];
                if (digit [6]) HEX6 <= ~ hgfedcba [$left (HEX6):0];
                if (digit [7]) HEX7 <= ~ hgfedcba [$left (HEX7):0];

                if (digit [0]) dp[0] <=  hgfedcba [$left (HEX0) + 1];
                if (digit [1]) dp[1] <=  hgfedcba [$left (HEX1) + 1];
                if (digit [2]) dp[2] <=  hgfedcba [$left (HEX2) + 1];
                if (digit [3]) dp[3] <=  hgfedcba [$left (HEX3) + 1];
                if (digit [4]) dp[4] <=  hgfedcba [$left (HEX4) + 1];
                if (digit [5]) dp[5] <=  hgfedcba [$left (HEX5) + 1];
                if (digit [6]) dp[6] <=  hgfedcba [$left (HEX6) + 1];
                if (digit [7]) dp[7] <=  hgfedcba [$left (HEX7) + 1];
            end
        end

        `ifdef USE_HIGH_LED_FOR_7SEG_DP
            assign LEDR [w_led - 1 : w_lab_led] = dp;
        `endif

    `endif

    //------------------------------------------------------------------------

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
        .hsync       ( VGA_HS    ),
        .vsync       ( VGA_VS    ),
        .display_on  (           ),
        .hpos        ( x10       ),
        .vpos        ( y10       ),
        .pixel_clk   ( VGA_CLK   )
    );

    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N  = 0;

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [0] ),
        .ws    ( GPIO [2] ),
        .sck   ( GPIO [4] ),
        .sd    ( GPIO [5] ),
        .value ( mic      )
    );

    assign GPIO [1] = 1'b0;  // GND
    assign GPIO [3] = 1'b1;  // VCC

    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz   )
    )
    i_audio
    (
        .clk     ( clk       ),
        .reset   ( rst       ),
        .data_in ( sound     ),
        .mclk    ( GPIO [33] ),
        .bclk    ( GPIO [31] ),
        .lrclk   ( GPIO [27] ),
        .sdata   ( GPIO [29] )
    );

    // VCC and GND for i2s_audio_out are on dedicated pins

endmodule
