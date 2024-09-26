`include "config.svh"
`include "lab_specific_board_config.svh"

//--- VGA external ---
   `define VGA666_BOARD
// `define PMOD_VGA_BOARD

module board_specific_top
# (
    parameter clk_mhz  = 50,

              w_key    = 2,
              w_sw     = 4,
              w_led    = 8,
              w_digit  = 0,
              w_gpio   = 36,

              // GPIO_0 [31], [33], [35]  are reserved for tm1638.
              // GPIO_1 [26], [28], [30], [32] are reserved for I2S audio.
              // GPIO_0[5:0] are reserved for INMP 441 I2S microphone.

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                    FPGA_CLK1_50,

    input  [w_key     - 1:0] KEY,
    input  [w_sw      - 1:0] SW,
    output [w_led     - 1:0] LED,             // LEDG onboard

    inout  [w_gpio    - 1:0] GPIO_0,
    inout  [w_gpio    - 1:0] GPIO_1
);

    //------------------------------------------------------------------------

    localparam w_lab_sw   = w_sw - 1;         // One onboard SW is used as a reset

    //------------------------------------------------------------------------

    wire                  clk    = FPGA_CLK1_50;

    wire                  rst    = SW [w_lab_sw];

    // Switches

    wire [ w_lab_sw  - 1:0] lab_sw  = SW [w_lab_sw - 1:0];

    // A dynamic seven-segment display

    wire [             7:0] abcdefgh;

    // Graphics

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    wire                    vs, hs;

    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;

    // Microphone, sound output and UART

    wire [            23:0] mic;
    wire [            15:0] sound;

    // FIXME: Should be assigned to some GPIO!
    wire                  UART_TX;
    wire                  UART_RX = '1;

    //------------------------------------------------------------------------

    localparam w_tm_key     = 8,
               w_tm_led     = 8,
               w_tm_digit   = 8;

    //------------------------------------------------------------------------

    `ifdef DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        localparam w_lab_key   = w_tm_key   > w_key   ? w_tm_key   : w_key   ,
                   w_lab_led   = w_tm_led   > w_led   ? w_tm_led   : w_led   ,
                   w_lab_digit = w_tm_digit > w_digit ? w_tm_digit : w_digit ;

    `else  // Concatenate the signals

        localparam w_lab_key   = w_tm_key   + w_key   ,
                   w_lab_led   = w_tm_led   + w_led   ,
                   w_lab_digit = w_tm_digit + w_digit ;
    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    //------------------------------------------------------------------------

    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR

        assign lab_key = { tm_key, ~ KEY };

        assign { tm_led   , LED   } = lab_led;
        assign             tm_digit = lab_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638

        assign lab_key = { ~ KEY, tm_key };

        assign { LED   , tm_led   } = lab_led;
        assign             tm_digit = lab_digit;

    `else  // DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        always_comb
        begin
            lab_key = '0;

            lab_key [w_key    - 1:0] |= ~ KEY;
            lab_key [w_tm_key - 1:0] |= tm_key;
        end

        assign LED      = lab_led   [w_led      - 1:0];
        assign tm_led   = lab_led   [w_tm_led   - 1:0];

        assign tm_digit = lab_digit [w_tm_digit - 1:0];

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz       ),
        .w_key         (   w_lab_key     ),
        .w_sw          (   w_lab_sw      ),
        .w_led         (   w_lab_led     ),
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
        .sw            (   lab_sw        ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   lab_digit     ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .uart_rx       (   UART_RX       ),
        .uart_tx       (   UART_TX       ),

        .gpio          (   GPIO_0        )
    );

    //------------------------------------------------------------------------

    // External VGA out at GPIO_1
    `ifdef  VGA666_BOARD

        // 4 bit color used
        assign GPIO_1 [35] = vs;            // vga666_pi_Vsync - JP7 pin 40
        assign GPIO_1 [33] = hs;            // vga666_pi_Hsync - JP7 pin 38
        // R
        assign GPIO_1 [13] = red [0];       // vga666_red[4]   - JP7 pin 16
        assign GPIO_1 [19] = red [1];       // vga666_red[5]   - JP7 pin 22
        assign GPIO_1 [ 5] = red [2];       // vga666_red[6]   - JP7 pin 6
        assign GPIO_1 [ 3] = red [3];       // vga666_red[7]   - JP7 pin 4
        // G
        assign GPIO_1 [ 7] = green [0];     // vga666_green[4] - JP7 pin 8
        assign GPIO_1 [21] = green [1];     // vga666_green[5] - JP7 pin 24
        assign GPIO_1 [17] = green [2];     // vga666_green[6] - JP7 pin 20
        assign GPIO_1 [15] = green [3];     // vga666_green[7] - JP7 pin 18
        // B
        assign GPIO_1 [23] = blue [0];      // vga666_blue[4]  - JP7 pin 26
        assign GPIO_1 [ 9] = blue [1];      // vga666_blue[5]  - JP7 pin 10
        assign GPIO_1 [11] = blue [2];      // vga666_blue[6]  - JP7 pin 14
        assign GPIO_1 [25] = blue [3];      // vga666_blue[7]  - JP7 pin 28
                                            // vga666_GND      - JP7 pin 30

    `elsif PMOD_VGA_BOARD

        assign GPIO_1 [ 7] = vs;            // JP7 pin  8
        assign GPIO_1 [ 5] = hs;            // JP7 pin  6
        // R
        assign GPIO_1 [35] = red [0];       // JP7 pin 40
        assign GPIO_1 [33] = red [1];       // JP7 pin 38
        assign GPIO_1 [31] = red [2];       // JP7 pin 36
        assign GPIO_1 [29] = red [3];       // JP7 pin 34
        // G
        assign GPIO_1 [25] = green [0];     // JP7 pin 28
        assign GPIO_1 [23] = green [1];     // JP7 pin 26
        assign GPIO_1 [21] = green [2];     // JP7 pin 24
        assign GPIO_1 [19] = green [3];     // JP7 pin 22
        // B
        assign GPIO_1 [17] = blue [0];      // JP7 pin 20
        assign GPIO_1 [15] = blue [1];      // JP7 pin 18
        assign GPIO_1 [13] = blue [2];      // JP7 pin 16
        assign GPIO_1 [11] = blue [3];      // JP7 pin 14
                                            // P-MOD_GND  - JP7 pin 30
                                            // P-MOD_3V3  - JP7 pin 29

    `endif

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

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .H_DISPLAY   ( screen_width  ),
            .V_DISPLAY   ( screen_height ),
            .CLK_MHZ     ( clk_mhz       )
        )
        i_vga
        (
            .clk         ( clk           ),
            .rst         ( rst           ),
            .hsync       ( hs            ),
            .vsync       ( vs            ),
            .display_on  (               ),
            .hpos        ( x10           ),
            .vpos        ( y10           ),
            .pixel_clk   (               )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz    ),
            .w_digit  ( w_tm_digit )    // fake parameter, digit count is hardcode in tm1638_board_controller
        )
        i_ledkey
        (
            .clk      ( clk         ),
            .rst      ( rst         ),  // Don't make reset tm1638_board_controller by it's tm_key
            .hgfedcba ( hgfedcba    ),
            .digit    ( tm_digit    ),
            .ledr     ( tm_led      ),
            .keys     ( tm_key      ),
            .sio_clk  ( GPIO_0 [27] ),  // JP1 pin 32
            .sio_stb  ( GPIO_0 [29] ),  // JP1 pin 34
            .sio_data ( GPIO_0 [31] )   // JP1 pin 36
        );                              // JP1 pin 30 - GND, pin 29 - VCC 3.3V

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz    )
        )
        i_microphone
        (
            .clk     ( clk        ),
            .rst     ( rst        ),
            .lr      ( GPIO_0 [0] ),  // JP1 pin 1
            .ws      ( GPIO_0 [2] ),  // JP1 pin 3
            .sck     ( GPIO_0 [4] ),  // JP1 pin 5
            .sd      ( GPIO_0 [5] ),  // JP1 pin 6
            .value   ( mic        )
        );

        assign GPIO_0 [1] = 1'b0;   // GND - JP1 pin 2
        assign GPIO_0 [3] = 1'b1;   // VCC - JP1 pin 4

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
            .mclk    ( GPIO_1 [32] ), // JP7 pin 37
            .bclk    ( GPIO_1 [30] ), // JP7 pin 35
            .lrclk   ( GPIO_1 [26] ), // JP7 pin 31
            .sdata   ( GPIO_1 [28] )  // JP7 pin 33
        );                            // JP7 pin 12 - GND, pin 29 - VCC 3.3V (30-45 mA)

    `endif

endmodule
