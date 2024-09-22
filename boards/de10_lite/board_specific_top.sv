`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 2,
              w_sw          = 10,
              w_led         = 10,
              w_digit       = 6,
              w_gpio        = 36,             // GPIO[5:0] reserved for mic

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height ),

              w_arduino     = 16
)
(
    input                     MAX10_CLK1_50,

    input  [ w_key     - 1:0] KEY,
    input  [ w_sw      - 1:0] SW,
    output [ w_led     - 1:0] LEDR,

    output logic        [7:0] HEX0,
    output logic        [7:0] HEX1,
    output logic        [7:0] HEX2,
    output logic        [7:0] HEX3,
    output logic        [7:0] HEX4,
    output logic        [7:0] HEX5,

    output                    VGA_HS,
    output                    VGA_VS,
    output [ w_red     - 1:0] VGA_R,
    output [ w_green   - 1:0] VGA_G,
    output [ w_blue    - 1:0] VGA_B,

    inout  [ w_gpio    - 1:0] GPIO,

    output                    ARDUINO_RESET_N,
    inout  [ w_arduino - 1:0] ARDUINO_IO
);

    //------------------------------------------------------------------------

    localparam w_lab_sw = w_sw - 1;  // One onboard SW is used as a reset

    //------------------------------------------------------------------------

    wire clk = MAX10_CLK1_50;
    wire rst = SW [w_sw - 1];

    assign ARDUINO_RESET_N = ~ rst;

    // Keys, switches, LEDs

    wire [ w_lab_sw  - 1:0] lab_sw = SW [w_lab_sw - 1:0];

    // A dynamic seven-segment display

    wire [             7:0] abcdefgh;
    wire [ w_digit   - 1:0] digit;

    // Graphics

    wire                    display_on;

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;

    assign VGA_R = display_on ? red   : '0;
    assign VGA_G = display_on ? green : '0;
    assign VGA_B = display_on ? blue  : '0;

    // Microphone and sound output

    wire [            23:0] mic;
    wire [            15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz            ),
        .w_key         (   w_key              ),
        .w_sw          (   w_lab_sw           ),
        .w_led         (   w_led              ),
        .w_digit       (   w_digit            ),
        .w_gpio        (   w_arduino + w_gpio ),

        .screen_width  (   screen_width       ),
        .screen_height (   screen_height      ),

        .w_red         (   w_red              ),
        .w_green       (   w_green            ),
        .w_blue        (   w_blue             )
    )
    i_lab_top
    (
        .clk           (   clk                ),
        .slow_clk      (   slow_clk           ),
        .rst           (   rst                ),

        .key           ( ~ KEY                ),
        .sw            (   lab_sw             ),

        .led           (   LEDR               ),

        .abcdefgh      (   abcdefgh           ),
        .digit         (   digit              ),

        .x             (   x                  ),
        .y             (   y                  ),

        .red           (   red                ),
        .green         (   green              ),
        .blue          (   blue               ),

        .uart_rx       (                      ),
        .uart_tx       (                      ),

        .mic           (   mic                ),
        .sound         (   sound              ),

        .gpio          ( { ARDUINO_IO, GPIO } )
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

        assign HEX0 = digit [0] ? ~ hgfedcba : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba : '1;
        assign HEX4 = digit [4] ? ~ hgfedcba : '1;
        assign HEX5 = digit [5] ? ~ hgfedcba : '1;

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 } <= '1;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba;
                if (digit [1]) HEX1 <= ~ hgfedcba;
                if (digit [2]) HEX2 <= ~ hgfedcba;
                if (digit [3]) HEX3 <= ~ hgfedcba;
                if (digit [4]) HEX4 <= ~ hgfedcba;
                if (digit [5]) HEX5 <= ~ hgfedcba;
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
            .clk     ( clk      ),
            .rst     ( rst      ),
            .lr      ( GPIO [0] ),  // JP1 pin 1
            .ws      ( GPIO [2] ),  // JP1 pin 3
            .sck     ( GPIO [4] ),  // JP1 pin 5
            .sd      ( GPIO [5] ),  // JP1 pin 6
            .value   ( mic      )
        );

        assign GPIO [1] = 1'b0;  // GND - JP1 pin 2
        assign GPIO [3] = 1'b1;  // VCC - JP1 pin 4

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
            .mclk    ( GPIO [33] ), // JP1 pin 38
            .bclk    ( GPIO [31] ), // JP1 pin 36
            .lrclk   ( GPIO [27] ), // JP1 pin 32
            .sdata   ( GPIO [29] )  // JP1 pin 34
        );                          // JP1 pin 30 - GND, pin 29 - VCC 3.3V (30-45 mA)

        // VCC and GND for i2s_audio_out are on dedicated pins

    `endif

endmodule
