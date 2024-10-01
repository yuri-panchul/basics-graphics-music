`include "config.svh"
`include "lab_specific_board_config.svh"

`undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE   // uses GPIO 0,1 and 2
//`undef INSTANTIATE_MICROPHONE_INTERFACE_MODULE      // uses GPIO 3,4,5 and 6
//`undef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE    // uses GPIO 7,8,9 and 10
//`undef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

//`undef HAVE_PCM5102

module board_specific_top
# (
    parameter   clk_mhz   = 25,
                pixel_mhz = 25,
                w_key     = 4,
                w_sw      = 2,
                w_led     = 4,
                w_digit   = 0,
                w_gpio    = 12,

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
    output [w_red       - 1:0]  VGA_R,
    output [w_green     - 1:0]  VGA_G,
    output [w_blue      - 1:0]  VGA_B,

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

    wire  [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;
    wire  [             15:0] sound;

    wire [w_x          - 1:0] x;
    wire [w_y          - 1:0] y;

   //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = lab_led;
    `else                   // TM1638 module is not connected

        assign rst      = KEY [w_key - 1];
        assign lab_key  = KEY [w_key - 1:0];

        assign LED      = lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;
    wire slow_clk_local;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk_local), .*);

    DCCA slow_clk_buf (.CLKI(slow_clk_local), .CLKO(slow_clk), .CE(1));


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
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( VGA_HS     ),
            .vsync       ( VGA_VS     ),
            .display_on  (            ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
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
