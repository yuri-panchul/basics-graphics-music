// Credits: https://github.com/icebreaker-fpga/icebreaker-verilog-examples

`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter   clk_mhz       = 12,
                pixel_mhz     = 25,
                w_key         = 3, // One key is reserved for reset
                w_sw          = 0,
                w_led         = 5,
                w_digit       = 0,
                w_gpio        = 24,

                screen_width  = 640,
                screen_height = 480,

                w_red         = 8,
                w_green       = 8,
                w_blue        = 8,

                w_x           = $clog2 ( screen_width  ),
                w_y           = $clog2 ( screen_height )
)
(
    input                       CLK,
    input                       KEY,  // Only 1 independent key, other keys on GPIO
    input                       UART_RX,
    output                      UART_TX,
    inout  [w_gpio      - 1:0]  GPIO
);

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_lab_key   = w_key,
                   w_lab_led   = w_led,
                   w_lab_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire                      rst;
    wire                      pixel_clk;

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] lab_red;
    wire  [w_green     - 1:0] lab_green;
    wire  [w_blue      - 1:0] lab_blue;

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        localparam lab_mhz = pixel_mhz;
        assign     clk     = pixel_clk;

    `else

        localparam lab_mhz = clk_mhz;
        assign     clk     = CLK;

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        wire rst_on_power_up;
        imitate_reset_on_power_up i_reset_on_power_up (clk, rst_on_power_up);

        assign rst          = rst_on_power_up | tm_key [w_tm_key - 1];
        assign lab_key      = tm_key [w_tm_key - 1:0];

        assign tm_led       = lab_led;
        assign tm_digit     = lab_digit;

    `else                   // TM1638 module is not connected

        assign rst          = ~ KEY;
        assign lab_key      =  GPIO [w_gpio - 1 -: w_key];

        assign GPIO [20:16] = lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;
    wire slow_clk_local;

    slow_clk_gen # (.fast_clk_mhz (lab_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk_local), .*);

    SB_GB clk_buf (.USER_SIGNAL_TO_GLOBAL_BUFFER(slow_clk_local), .GLOBAL_BUFFER_OUTPUT(slow_clk));

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( lab_mhz       ),
        .w_key         ( w_lab_key     ),
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
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( lab_key   ),
        .sw       ( lab_key   ),

        .led      ( lab_led   ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( lab_digit ),

        .x        ( x         ),
        .y        ( y         ),

        .red      ( lab_red   ),
        .green    ( lab_green ),
        .blue     ( lab_blue  ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .gpio     ( GPIO      ),

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
            .clk_mhz ( lab_mhz    ),
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
            .sio_clk  ( GPIO [21] ),
            .sio_stb  ( GPIO [22] ),
            .sio_data ( GPIO [23] )
        );

    `endif


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        // 25.125 MHz pixel clock
        SB_PLL40_PAD #(
            .FEEDBACK_PATH ( "SIMPLE"   ),
            .DIVR          ( 4'b0000    ),  // DIVR =  0
            .DIVF          ( 7'b1000010 ),  // DIVF = 66
            .DIVQ          ( 3'b101     ),  // DIVQ =  5
            .FILTER_RANGE  ( 3'b001     )   // FILTER_RANGE = 1
        ) pll (
            .LOCK       (           ),
            .RESETB     ( 1'b1      ),
            .BYPASS     ( 1'b0      ),
            .PACKAGEPIN ( CLK       ), // 12 MHz
            .PLLOUTCORE ( pixel_clk )  // 25.125 MHz
        );

        //--------------------------------------------------------------------

        logic hsync, vsync, display_on;

        vga
        # (
            .HPOS_WIDTH  ( w_x       ),
            .VPOS_WIDTH  ( w_y       ),
            .CLK_MHZ     ( pixel_mhz ),
            .PIXEL_MHZ   ( pixel_mhz )
        )
        i_vga
        (
            .clk         ( pixel_clk      ),
            .rst         ( rst            ),
            .hsync       ( hsync          ),
            .vsync       ( vsync          ),
            .display_on  ( display_on     ),
            .hpos        ( x              ),
            .vpos        ( y              )
        );

        //--------------------------------------------------------------------

        logic [15:0] rising_edge_data, falling_edge_data;

        assign rising_edge_data = {
            lab_red  [7], lab_red  [5], lab_red[3], lab_red[1],
            lab_red  [6], lab_red  [4], lab_red[2], lab_red[0],
            lab_green[7], lab_green[5], 1'b1,       hsync,
            lab_green[6], lab_green[4], display_on, vsync
        };

        assign falling_edge_data = {
            lab_green[3], lab_green[1], lab_blue[7], lab_blue[5],
            lab_green[2], lab_green[0], lab_blue[6], lab_blue[4],
            lab_blue [3], lab_blue [1], 1'b0,        hsync,
            lab_blue [2], lab_blue [0], display_on,  vsync
        };

        // DDR IO outputs for DVI PMOD
        SB_IO #(
            .PIN_TYPE ( 6'b01_0000 )  // PIN_OUTPUT_DDR
        ) dvi_ddr_iob [15:0] (
            .PACKAGE_PIN ( GPIO[15:0]        ),
            .D_OUT_0     ( rising_edge_data  ),
            .D_OUT_1     ( falling_edge_data ),
            .OUTPUT_CLK  ( pixel_clk         )
        );

    `else

        // Only instantiate sound logic if DVI is not used, because GPIO
        // pins are shared between those modules

        `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

            inmp441_mic_i2s_receiver
            # (
                .clk_mhz ( lab_mhz )
            )
            i_microphone
            (
                .clk   ( clk      ),
                .rst   ( rst      ),
                .lr    ( GPIO [0] ),
                .ws    ( GPIO [1] ),
                .sck   ( GPIO [2] ),
                .sd    ( GPIO [3] ),
                .value ( mic      )
            );

        `endif

        //------------------------------------------------------------------------

        `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

            i2s_audio_out
            # (
                .clk_mhz ( lab_mhz )
            )
            inst_pmod_amp3
            (
                .clk     ( clk       ),
                .reset   ( rst       ),
                .data_in ( sound     ),

                .mclk    ( GPIO [8]  ),
                .bclk    ( GPIO [9]  ),
                .sdata   ( GPIO [10] ),
                .lrclk   ( GPIO [11] )
            );

        `endif

    `endif

endmodule
