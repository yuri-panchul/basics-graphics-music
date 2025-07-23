`define FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

module board_specific_top
# (
    parameter clk_mhz       = 25,

              w_key         = 4,
              w_sw          = 16,
              w_led         = 16,
              w_digit       = 8,
              w_gpio        = 20,

              screen_width  = 800,
              screen_height = 480,

              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   CLK,

    input  [w_key   - 1:0]  KEY,
    input  [w_sw    - 1:0]  SW,
    output [w_led   - 1:0]  LED,

    input                   UART2_RXD,
    output                  UART2_TXD,

    output [          7:0]  HGFEDCBA,
    output [w_digit - 1:0]  DIGIT,

    inout  [         19:0]  GPIO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_lab_key   = w_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_led,
                   w_lab_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (~ lab_led);

    `else                 // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign lab_key  = ~ KEY [w_key - 1:0];

        assign LED      = lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    wire  [w_x - 1:0] mirrored_x = w_x' (screen_width  - 1 - x);
    wire  [w_y - 1:0] mirrored_y = w_y' (screen_height - 1 - y);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_lab_key     ),  // The last key is used for a reset
        .w_sw          ( w_lab_key     ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
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
        .digit         ( lab_digit     ),

        .x             ( mirrored_x    ),
        .y             ( mirrored_y    ),

        .red           ( LCD_R         ),
        .green         ( LCD_G         ),
        .blue          ( LCD_B         ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),

        .gpio          ( GPIO          )
    );

    //------------------------------------------------------------------------

        wire [$left (abcdefgh):0] hgfedcba;
        `SWAP_BITS (hgfedcba, abcdefgh);

        assign HGFEDCBA = ~ hgfedcba;
        assign DIGIT    = lab_digit;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz        ),
            .w_digit  ( w_tm_digit     )
        )
        i_tm1638
        (
            .clk      ( clk            ),
            .rst      ( rst            ),
            .hgfedcba ( hgfedcba       ),
            .digit    ( tm_digit       ),
            .ledr     ( tm_led         ),
            .keys     ( tm_key         ),
            .sio_data ( GPIO[8]        ),
            .sio_clk  ( GPIO[9]        ),
            .sio_stb  ( GPIO[10]        )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz  ( clk_mhz    )
        )
        i_microphone
        (
            .clk      ( clk        ),
            .rst      ( rst        ),
            .lr       ( GPIO[0]    ),
            .ws       ( GPIO[1]    ),
            .sck      ( GPIO[2]    ),
            .sd       ( GPIO[6]    ),
            .value    ( mic        )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz  ( clk_mhz    )
        )
        inst_audio_out
        (
            .clk      ( clk        ),
            .reset    ( rst        ),
            .data_in  ( sound      ),
            .mclk     ( GPIO[4]    ),
            .bclk     ( GPIO[5]    ),
            .sdata    ( GPIO[6]    ),
            .lrclk    ( GPIO[7]    )
        );

    `endif

endmodule
