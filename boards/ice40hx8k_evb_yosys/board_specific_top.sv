`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter   clk_mhz = 100,
                w_key   = 3, // w_ket[2] is used for RST and is wired to JTAG_TMS.
                w_sw    = 2,
                w_led   = 2,
                w_digit = 0,
                w_gpio  = 12,

                screen_width  = 640,
                screen_height = 480,

                w_red         = 4,
                w_green       = 4,
                w_blue        = 4,

                w_x           = $clog2 ( screen_width  ),
                w_y           = $clog2 ( screen_height )
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    output                      VGA_HS,
    output                      VGA_VS,
    output [              3:0]  VGA_R,
    output [              3:0]  VGA_G,
    output [              3:0]  VGA_B,

    inout  [w_gpio      - 1:0]  GPIO
);

    wire clk = CLK;

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;


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
    wire  [             23:0] mic;

   //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign lab_key  = ~ KEY [w_key - 1:0];

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;
    wire slow_clk_local;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk_local), .*);

    SB_GB clk_buf (.USER_SIGNAL_TO_GLOBAL_BUFFER(slow_clk_local), .GLOBAL_BUFFER_OUTPUT(slow_clk));

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),
        .w_key         ( w_lab_key     ),  // The last key is used for a reset
        .w_sw          ( w_lab_sw      ),
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
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( lab_key   ),
        .sw       (           ),

        .led      ( lab_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( lab_digit ),

        .x        ( x         ),
        .y        ( y         ),

        .x        ( x         ),
        .y        ( y         ),

        .red      ( VGA_R     ),
        .green    ( VGA_G     ),
        .blue     ( VGA_B     ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),


        `ifndef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
            `ifndef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
                `ifndef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
                    `ifndef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        .gpio     ( GPIO      ),
                    `endif
                `endif
            `endif
        `endif

        .mic      ( mic       ),
        .sound    ( sound     )
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
            .clk_mhz ( clk_mhz ),
            .w_digit ( w_tm_digit )
        )
        i_tm1638
        (
            .clk      ( clk       ),
            .rst      ( rst       ),
            .hgfedcba ( hgfedcba  ),
            .digit    ( tm_digit  ),
            .ledr     ( tm_led    ),
            .keys     ( tm_key    ),
            .sio_clk  ( GPIO [0]  ),
            .sio_stb  ( GPIO [1]  ),
            .sio_data ( GPIO [2]  )
        );
    `endif


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz )
        )
        i_microphone
        (
            .clk   ( clk      ),
            .rst   ( rst      ),
            .lr    ( GPIO [3] ),
            .ws    ( GPIO [4] ),
            .sck   ( GPIO [5] ),
            .sd    ( GPIO [6] ),
            .value ( mic      )
        );

    `endif


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        `ifdef HAVE_PCM5102

            i2s_audio_out
            # (
                .clk_mhz ( clk_mhz )
            )
            inst_pcm5102
            (
                .clk     ( clk     ),
                .reset   ( rst     ),
                .data_in ( sound   ),

                .mclk    ( GPIO  [7] ),
                .bclk    ( GPIO  [8] ),
                .sdata   ( GPIO  [9] ),
                .lrclk   ( GPIO [10] )
            );

        `else

            i2s_audio_out
            # (
                .clk_mhz ( clk_mhz )
            )
            inst_pmod_amp3
            (
                .clk     ( clk     ),
                .reset   ( rst     ),
                .data_in ( sound   ),

                .mclk    ( GPIO  [7] ),
                .bclk    ( GPIO  [8] ),
                .sdata   ( GPIO  [9] ),
                .lrclk   ( GPIO [10] )
            );

        `endif

    `endif

endmodule
