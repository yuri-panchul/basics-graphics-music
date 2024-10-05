`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              // We use sw as an alias to key on Tang Prime 25K,
              // either with or without TM1638

              w_key         = 2,
              w_sw          = 0,
              w_led         = 0,
              w_digit       = 0,
              w_gpio        = 38,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )

              // gpio 0..5 are reserved for INMP 441 I2S microphone.
              // Odd gpio 17..27 are reserved I2S audio.
              // Odd gpio 29..37 are reserved for TM1638.
)
(
    input                  CLK,

    input  [w_key  - 1:0]  KEY,

    input                  UART_RX,
    output                 UART_TX,

    inout  [w_gpio - 1:0]  GPIO,

    `ifdef ENABLE_DVIuytuytu

    output                 TMDS_CLK_N,
    output                 TMDS_CLK_P,
    output [         2:0]  TMDS_D_N,
    output [         2:0]  TMDS_D_P,

    `else

    inout  [         7:0]  PMOD_0,

    `endif

    inout  [         7:0]  PMOD_1,
    inout  [         7:0]  PMOD_2
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    //------------------------------------------------------------------------

    // Keys, LEDs, seven segment display

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    wire  [              7:0] abcdefgh;

    // Graphics

    wire                 display_on;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] red;
    wire  [w_green     - 1:0] green;
    wire  [w_blue      - 1:0] blue;

    // Sound

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    wire rst_on_power_up;
    imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

    wire tm_rst;

    // `define USE_KEY_0_AS_TM_RESET

    `ifdef USE_KEY_0_AS_TM_RESET
        assign tm_rst  = rst_on_power_up | KEY [0];
    `else
        assign tm_rst  = rst_on_power_up;
    `endif

    wire                  rst     = tm_rst | tm_key [w_tm_key - 1];
    wire [w_tm_key - 1:0] lab_key = tm_key | w_tm_key' (KEY);

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_tm_key      ),
        .w_sw          ( w_tm_key      ),
        .w_led         ( w_tm_led      ),
        .w_digit       ( w_tm_digit    ),
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
        .sw            ( lab_key       ),

        .led           ( tm_led        ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( tm_digit      ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

        .uart_rx       ( UART_RX       ),
        .uart_tx       ( UART_TX       ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          ( GPIO          )
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

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz    ),
            .w_digit  ( w_tm_digit )
        )
        i_tm1638
        (
            .clk      ( clk        ),
            .rst      ( tm_rst     ),
            .hgfedcba ( hgfedcba   ),
            .digit    ( tm_digit   ),
            .ledr     ( tm_led     ),
            .keys     ( tm_key     ),
            .sio_data ( PMOD_0 [5] ),
            .sio_clk  ( PMOD_0 [6] ),
            .sio_stb  ( PMOD_0 [7] )
        );

    `endif
/*
    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz    )
    )
    i_microphone
    (
        .clk     ( clk        ),
        .rst     ( rst        ),
        .lr      ( gpio   [0] ),
        .ws      ( gpio   [2] ),
        .sck     ( gpio   [4] ),
        .sd      ( gpio   [5] ),
        .value   ( mic        )
    );

    assign gpio [1] = 1'b0;  // GND
    assign gpio [3] = 1'b1;  // VCC

    //------------------------------------------------------------------------

    `ifndef ENABLE_DVI

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz     )
    )
    inst_audio_out
    (
        .clk     ( clk       ),
        .reset   ( rst       ),
        .data_in ( sound     ),

        .mclk    ( pmod_0[4] ),
        .bclk    ( pmod_0[5] ),
        .sdata   ( pmod_0[6] ),
        .lrclk   ( pmod_0[7] )
    );

    `endif

    //------------------------------------------------------------------------

    // Pmod VGA

    assign pmod_1 = { green [7:4], 2'b0, vsync, hsync };
    assign pmod_2 = { red   [7:4], blue [7:4] };
*/

endmodule
