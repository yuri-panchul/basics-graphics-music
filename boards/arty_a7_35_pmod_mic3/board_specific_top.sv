`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 100,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 4,
              w_led         = 4,
              w_digit       = 0,
              w_gpio        = 42,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                  CLK100MHZ,
    input                  ck_rst,

    input  [w_key  - 1:0]  btn,

    input  [w_sw   - 1:0]  sw,
    output [w_led  - 1:0]  led,

    output                 led0_b,
    output                 led0_g,
    output                 led0_r,

    output                 led1_b,
    output                 led1_g,
    output                 led1_r,

    output                 led2_b,
    output                 led2_g,
    output                 led2_r,

    output                 led3_b,
    output                 led3_g,
    output                 led3_r,

    input                  uart_txd_in,
    output                 uart_rxd_out,

    inout  [7:0]           ja,
    inout  [7:0]           jb,  // VGA_B and VGA_R
    inout  [7:0]           jc,  // VGA_G and VGA_HS, VGA, VS
    inout  [7:0]           jd,

    inout                  ck_io0,
    inout                  ck_io1,
    inout                  ck_io2,
    inout                  ck_io3,
    inout                  ck_io4,
    inout                  ck_io5,
    inout                  ck_io6,
    inout                  ck_io7,
    inout                  ck_io8,
    inout                  ck_io9,
    inout                  ck_io10,
    inout                  ck_io11,
    inout                  ck_io12,
    inout                  ck_io13,

    inout [25:14]          dummy_ck_io25_14,

    inout                  ck_io26,
    inout                  ck_io27,
    inout                  ck_io28,
    inout                  ck_io29,
    inout                  ck_io30,
    inout                  ck_io31,
    inout                  ck_io32,
    inout                  ck_io33,
    inout                  ck_io34,
    inout                  ck_io35,
    inout                  ck_io36,
    inout                  ck_io37,
    inout                  ck_io38,
    inout                  ck_io39,
    inout                  ck_io40,
    inout                  ck_io41
);

    //------------------------------------------------------------------------

    wire clk =   CLK100MHZ;
    wire rst = ~ ck_rst;


    //------------------------------------------------------------------------

    assign led0_b = 1'b0;
    assign led0_g = 1'b0;
    assign led0_r = 1'b0;

    assign led1_b = 1'b0;
    assign led1_g = 1'b0;
    assign led1_r = 1'b0;

    assign led2_b = 1'b0;
    assign led2_g = 1'b0;
    assign led2_r = 1'b0;

    assign led3_b = 1'b0;
    assign led3_g = 1'b0;
    assign led3_r = 1'b0;

    //------------------------------------------------------------------------

    wire [w_x    - 1:0] x;
    wire [w_y    - 1:0] y;

    wire [       23:0] mic;
    wire [        7:0] abcdefgh;

    //------------------------------------------------------------------------

    //------------------------------------------------------------------------
    wire [w_gpio    - 1:0] gpio;
    //------------------------------------------------------------------------

    wire [        3:0] KEY    = btn;
    wire [ w_sw - 1:0] lab_sw = sw [w_sw - 1:0];

    localparam  w_tm_key     = 8,
                w_tm_led     = 8,
                w_tm_digit   = 8;

    `ifdef DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        localparam w_lab_key   = w_tm_key   > w_key   ? w_tm_key   : w_key   ,
                   w_lab_led   = w_tm_led   > w_led   ? w_tm_led   : w_led   ,
                   w_lab_digit = w_tm_digit > w_digit ? w_tm_digit : w_digit ;

    `else  // Concatenate the signals

        localparam w_lab_key   = w_tm_key   + w_key   ,
                   w_lab_led   = w_tm_led   + w_led   ,
                   w_lab_digit = w_tm_digit + w_digit ;
    `endif


    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;


    //------------------------------------------------------------------------

    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR

        assign lab_key = { tm_key,  KEY };

        assign { tm_led   , led   } = lab_led;
        assign             tm_digit = lab_digit;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638

        assign lab_key = {  KEY, tm_key };

        assign { led   , tm_led   } = lab_led;
        assign             tm_digit = lab_digit;

    `else  // DUPLICATE_TM1638_SIGNALS_WITH_REGULAR

        always_comb
        begin
            lab_key = '0;

            lab_key [w_key    - 1:0] |=  KEY;
            lab_key [w_tm_key - 1:0] |= tm_key;
        end

        assign led      = lab_led   [w_led      - 1:0];
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
        .clk_mhz       ( clk_mhz     ),
        .w_key         ( w_lab_key   ),
        .w_sw          ( w_sw        ),
        .w_led         ( w_lab_led   ),
        .w_digit       ( w_lab_digit ),
        .w_gpio        ( w_gpio      ),

        .screen_width  ( screen_width   ),
        .screen_height ( screen_height  ),

        .w_red         ( w_red          ),
        .w_green       ( w_green        ),
        .w_blue        ( w_blue         )
    )
    i_lab_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( lab_key   ),
        .sw       ( lab_sw    ),

        .led      ( lab_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( lab_digit ),

        .x        ( x         ),
        .y        ( y         ),

        .red      ( jb [7:4]  ),
        .green    ( jc [7:4]  ),
        .blue     ( jb [3:0]  ),

        .uart_rx  (uart_txd_in),
        .uart_tx  (uart_rxd_out),

        .mic      ( mic       ),
        .gpio     ( {
                    ck_io0,
                    ck_io1,
                    ck_io2,
                    ck_io3,
                    ck_io4,
                    ck_io5,
                    ck_io6,
                    ck_io7,
                    ck_io8,
                    ck_io9,
                    ck_io10,
                    ck_io11,
                    ck_io12,
                    ck_io13,

                    dummy_ck_io25_14,

                    ck_io26,
                    ck_io27,
                    ck_io28,
                    ck_io29,
                    ck_io30,
                    ck_io31,
                    ck_io32,
                    ck_io33,
                    ck_io34,
                    ck_io35,
                    ck_io36,
                    ck_io37,
                    ck_io38,
                    ck_io39,
                    ck_io40,
                    ck_io41
                   })
    );

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
            .hsync       ( jc [0]     ),
            .vsync       ( jc [1]     ),
            .display_on  (            ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

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

    tm1638_board_controller
    # (
        .w_digit   ( w_tm_digit ),  // fake parameter, digit count is hardcode in tm1638_board_controller
        .clk_mhz   ( clk_mhz    )
    )
    i_ledkey
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .hgfedcba  ( hgfedcba   ),
        .digit     ( tm_digit   ),
        .ledr      ( tm_led     ),
        .keys      ( tm_key     ),
        .sio_clk   ( ck_io40    ),
        .sio_stb   ( ck_io41    ),
        .sio_data  ( ck_io39    )
    );

   //------------------------------------------------------------------------

    `ifdef INMP441_MIC

    inmp441_mic_i2s_receiver
    #(
        .clk_mhz   ( clk_mhz    )
    )
    i_mic
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .lr        ( jd [5]     ),
        .ws        ( jd [4]     ),
        .sck       ( jd [7]     ),
        .sd        ( jd [6]     ),
        .value     ( mic        )
    );

    `else

    wire [11:0] mic_12;
    wire [11:0] mic_12_minus_offset = mic_12 - 12'h800;

    assign mic = { { 12 { mic_12_minus_offset [11] } }, mic_12_minus_offset };

    digilent_pmod_mic3_spi_receiver
    #(
        .clk_mhz   ( clk_mhz    )
    )
    i_mic
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .cs        ( jd [4]     ),
        .sck       ( jd [7]     ),
        .sdo       ( jd [6]     ),
        .value     ( mic_12     )
    );

    `endif

    //------------------------------------------------------------------------
    //TODO: Add Support for INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

    // `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

    //     i2s_audio_out
    //     # (
    //         .clk_mhz ( clk_mhz )
    //     )
    //     inst_pcm5102
    //     (
    //         .clk     ( clk     ),
    //         .reset   ( rst     ),
    //         .data_in (    ),

    //         .mclk    (   ),
    //         .bclk    (   ),
    //         .sdata   (   ),
    //         .lrclk   (   )
    //     );

    //     i2s_audio_out
    //     # (
    //         .clk_mhz ( clk_mhz )
    //     )
    //     inst_pmod_amp3
    //     (
    //         .clk     ( clk     ),
    //         .reset   ( rst     ),
    //         .data_in (    ),

    //         .mclk    (   ),
    //         .bclk    (   ),
    //         .sdata   (   ),
    //         .lrclk   (   )
    //     );

    // `endif


endmodule
