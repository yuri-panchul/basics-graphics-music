`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter   clk_mhz   = 25,
                pixel_mhz = 25,
                w_key     = 1,
                w_sw      = 0,
                w_led     = 1,
                w_digit   = 8,
                w_gpio    = 2,

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

    inout  [w_key       - 1:0]  KEY,

    output [w_led       - 1:0]  LED,

    output [              3:0]  HDMI_P,
    output [              3:0]  HDMI_N,

    inout  [w_gpio      - 1:0]  GPIO
);

    wire clk_250MHz, locked;

    clock i_clock (
        .clkin_25MHz  ( CLK        ),
        .clk_250MHz   ( clk_250MHz ),
        .clk_25MHz    ( clk        ),
        .locked       ( locked     )
    );

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
    wire                      vga_hs;
    wire                      vga_vs;
    wire [w_red         -1:0] vga_r;
    wire [w_green       -1:0] vga_g;
    wire [w_blue        -1:0] vga_b;
    wire                      vga_draw;


   //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = ~locked | tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

        assign rst      = ~locked | KEY [w_key - 1];
        assign lab_key  = '0;

    `endif

    assign LED[0] = ( lab_led[0] ? 1'b0 : 1'bz );

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

        .red      ( vga_r     ),
        .green    ( vga_g     ),
        .blue     ( vga_b     ),

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
            .sio_data ( KEY [0]   )
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
            .clk         ( clk         ),
            .rst         ( rst         ),
            .hsync       ( vga_hs      ),
            .vsync       ( vga_vs      ),
            .display_on  ( vga_draw    ),
            .hpos        ( x10         ),
            .vpos        ( y10         ),
            .pixel_clk   (             )
        );
        
        hdmi i_hdmi (
            .pixclk      ( clk         ),
            .clk_TMDS    ( clk_250MHz  ),
            .HSYNC       ( vga_hs      ),
            .VSYNC       ( vga_vs      ),
            .DRAW        ( vga_draw    ),
            .R           ( vga_r       ),
            .G           ( vga_g       ),
            .B           ( vga_b       ),
            .TMDSp       ( HDMI_P[2:0] ),
            .TMDSn       ( HDMI_N[2:0] ),
            .TMDSp_clock ( HDMI_P[3]   ),
            .TMDSn_clock ( HDMI_N[3]   )
        );

    `endif

    //------------------------------------------------------------------------


endmodule
