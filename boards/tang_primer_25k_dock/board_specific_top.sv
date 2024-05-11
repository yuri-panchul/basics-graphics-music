// TODO
// Find pins for the keys on the board
// Debug I2S output
// Check pin options in tcl file
// Find out the status of I2C gpio pin 11
// Parameterize red, green, blue width
// Create a variant of 25K with 7-segment, leds and buttons on pmod.

`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter   clk_mhz   = 50,
                pixel_mhz = 50,
                w_key     = 2,
                w_sw      = 0,
                w_led     = 0,
                w_digit   = 0,

                w_vgar    = 8,
                w_vgag    = 8,
                w_vgab    = 8,

                w_gpio    = 38

                // gpio 0..5 are reserved for INMP 441 I2S microphone.
                // Odd gpio 17..27 are reserved I2S audio.
                // Odd gpio 29..37 are reserved for TM1638.
)
(
    input                  clk,
    input  [w_key  - 1:0]  key,

    inout  [         7:0]  pmod_0,
    inout  [         7:0]  pmod_1,
    inout  [         7:0]  pmod_2,

    inout  [w_gpio - 1:0]  gpio
);

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire                      rst = tm_key [w_tm_key - 1];

    wire  [w_tm_led    - 1:0] led;

    wire  [              7:0] abcdefgh;
    wire  [w_tm_digit  - 1:0] digit;

    wire                      vsync;
    wire                      hsync;

    wire  [w_vgar      - 1:0] red;
    wire  [w_vgag      - 1:0] green;
    wire  [w_vgab      - 1:0] blue;

    wire  [             23:0] mic;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz   ( clk_mhz    ),
        .pixel_mhz ( pixel_mhz  ),

        .w_key     ( w_tm_key   ),
        .w_sw      ( w_tm_key   ),
        .w_led     ( w_tm_led   ),
        .w_digit   ( w_tm_digit ),

        .w_vgar    ( w_vgar     ),
        .w_vgag    ( w_vgag     ),
        .w_vgab    ( w_vgab     ),

        .w_gpio    ( w_gpio     )
    )
    i_top
    (
        .clk       ( clk        ),
        .slow_clk  ( slow_clk   ),
        .rst       ( rst        ),

        .key       ( tm_key     ),
        .sw        ( tm_key     ),

        .led       ( led        ),

        .abcdefgh  ( abcdefgh   ),
        .digit     ( digit      ),

        .vsync     ( vsync      ),
        .hsync     ( hsync      ),

        .red       ( red        ),
        .green     ( green      ),
        .blue      ( blue       ),

        .uart_rx   (            ),
        .uart_tx   (            ),

        .mic       ( mic        ),
        .gpio      ( gpio       )
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

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .lr    ( gpio   [0] ),
        .ws    ( gpio   [2] ),
        .sck   ( gpio   [4] ),
        .sd    ( gpio   [5] ),
        .value ( mic        )
    );

    assign gpio [1] = 1'b0;  // GND
    assign gpio [3] = 1'b1;  // VCC

    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz     )
    )
    i_audio
    (
        .clk     ( clk       ),
        .reset   ( rst       ),
        .data_in ( sound     ),
        .mclk    ( gpio [17] ),
        .bclk    ( gpio [19] ),
        .lrclk   ( gpio [23] ),
        .sdata   ( gpio [21] )
    );

    assign gpio [25] = 1'b0;  // GND
    assign gpio [27] = 1'b1;  // VCC

    //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz    ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk        ( clk       ),
        .rst        ( rst       ),
        .hgfedcba   ( hgfedcba  ),
        .digit      ( digit     ),
        .ledr       ( led       ),
        .keys       ( tm_key    ),
        .sio_clk    ( gpio [35] ),
        .sio_stb    ( gpio [33] ),
        .sio_data   ( gpio [37] )
    );

    assign gpio [31] = 1'b0;
    assign gpio [29] = 1'b1;

    //------------------------------------------------------------------------

    wire       tmds_clk_p,  tmds_clk_n;
    wire [2:0] tmds_data_p, tmds_data_n;

    dvi_tx i_dvi_tx
    (
        .I_rst_n        ( ~ rst         ),
        .I_rgb_clk      (   clk         ),
        .I_rgb_vs       (   vsync       ),
        .I_rgb_hs       (    hsync      ),
        .I_rgb_de       (   1'b1        ),
        .I_rgb_r        (   red         ),
        .I_rgb_g        (   green       ),
        .I_rgb_b        (   blue        ),
        .O_tmds_clk_p   (   tmds_clk_p  ),
        .O_tmds_clk_n   (   tmds_clk_n  ),
        .O_tmds_data_p  (   tmds_data_p ),
        .O_tmds_data_n  (   tmds_data_n )
    );

    assign { pmod_0 [0], pmod_0 [1], pmod_0 [2] } = tmds_data_p;
    assign pmod_0 [3] = tmds_clk_p;

    assign { pmod_0 [4], pmod_0 [5], pmod_0[6] } = tmds_data_n;
    assign pmod_0 [7] = tmds_clk_p;

endmodule
