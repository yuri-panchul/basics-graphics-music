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

    localparam w_de_sw = w_sw - 1;  // One onboard SW is used as a reset

    //------------------------------------------------------------------------

    wire clk = MAX10_CLK1_50;
    wire rst = SW [w_sw - 1];

    assign ARDUINO_RESET_N = ~ rst;

    // Keys, switches, LEDs

    wire [ w_de_sw - 1:0] de_sw = SW [w_de_sw - 1:0];

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

    localparam w_tm_key     = 8,
               w_tm_sw      = 8,
               w_tm_led     = 8,
               w_tm_digit   = 8;

    //------------------------------------------------------------------------

    `ifdef DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        localparam w_lab_key   = w_tm_key   > w_key   ? w_tm_key   : w_key   ,
                   w_lab_sw    = w_tm_sw    > w_de_sw ? w_tm_sw    : w_de_sw ,
                   w_lab_led   = w_tm_led   > w_led   ? w_tm_led   : w_led   ,
                   w_lab_digit = w_tm_digit > w_digit ? w_tm_digit : w_digit ;

    `else  // Concatenate the signals

        localparam w_lab_key   = w_tm_key   + w_key   ,
                   w_lab_sw    = w_tm_sw    + w_de_sw ,
                   w_lab_led   = w_tm_led   + w_led   ,
                   w_lab_digit = w_tm_digit + w_digit ;
    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_sw     - 1:0] tm_sw;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    logic [w_lab_sw    - 1:0] lab_sw;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    //------------------------------------------------------------------------

    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR

        assign lab_key = { tm_key, ~ KEY };
        assign lab_sw  = { tm_sw , de_sw };

        assign { tm_led, LEDR     } = lab_led;
        assign           tm_digit   = lab_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638

        assign lab_key = { ~ KEY, tm_key };
        assign lab_sw  = { de_sw, tm_sw  };

        assign { LEDR, tm_led   } = lab_led;
        assign         tm_digit   = lab_digit;

    `else  // DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        always_comb
        begin
            lab_key = '0;
            lab_sw  = '0;

            lab_key [w_key    - 1:0] |= ~ KEY;
            lab_key [w_tm_key - 1:0] |= tm_key;

            lab_sw [w_de_sw - 1:0] |= de_sw;
            lab_sw [w_tm_sw - 1:0] |= tm_sw;
        end

        assign LEDR     = lab_led   [w_led      - 1:0];
        assign tm_led   = lab_led   [w_tm_led   - 1:0];

        assign digit    = lab_digit [w_digit    - 1:0];
        assign tm_digit = lab_digit [w_tm_digit - 1:0];

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz            ),
        .w_key         (   w_lab_key          ),
        .w_sw          (   w_lab_sw           ),
        .w_led         (   w_lab_led          ),
        .w_digit       (   w_lab_digit        ),
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

        .key           (   lab_key            ),
        .sw            (   lab_sw             ),

        .led           (   lab_led            ),

        .abcdefgh      (   abcdefgh           ),
        .digit         (   lab_digit          ),

        .x             (   x                  ),
        .y             (   y                  ),

        .red           (   VGA_R              ),
        .green         (   VGA_G              ),
        .blue          (   VGA_B              ),

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
            .pixel_clk   (           )
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
            .clk_mhz ( clk_mhz     )
        )
        inst_audio_out
        (
            .clk     ( clk         ),
            .reset   ( rst         ),
            .data_in ( sound       ),
            .mclk    ( GPIO [32]   ), // JP1 pin 37
            .bclk    ( GPIO [30]   ), // JP1 pin 35
            .lrclk   ( GPIO [26]   ), // JP1 pin 31
            .sdata   ( GPIO [28]   )  // JP1 pin 33
        );                            // JP1 pin 30 - GND, pin 29 - VCC 3.3V (30-45 mA)

        // VCC and GND for i2s_audio_out are on dedicated pins

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_virtual_switches
        # (
            .clk_mhz  ( clk_mhz    )
        )
        i_ledkey
        (
            .clk      ( clk       ),
            .rst      ( rst       ),  // Don't make reset tm1638_board_controller by it's tm_key
            .hgfedcba ( hgfedcba  ),
            .digit    ( tm_digit  ),
            .switches ( tm_sw     ),
            .sio_stb  ( GPIO [27] ),  // JP1 pin 32
            .sio_clk  ( GPIO [29] ),  // JP1 pin 34
            .sio_data ( GPIO [31] )   // JP1 pin 36
        );                              // JP1 pin 30 - GND, pin 29 - VCC 3.3V

    `endif

endmodule
