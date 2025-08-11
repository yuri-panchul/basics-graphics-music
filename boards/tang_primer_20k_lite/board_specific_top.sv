`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 27,
              pixel_mhz     = 25,

              w_key         = 2,
              w_sw          = 3,
              w_led         = 0,
              w_digit       = 0,
              w_gpio        = 32,             // GPIO[5:0] reserved for mic

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

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3
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
    logic [w_lab_sw    - 1:0] lab_sw;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;

    // Graphics

// Look1
    wire                    display_on;

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;

    wire                    VGA_HS;
    wire                    VGA_VS;

    wire [ w_red     - 1:0] VGA_R = display_on ? red   : '0;
    wire [ w_green   - 1:0] VGA_G = display_on ? green : '0;
    wire [ w_blue    - 1:0] VGA_B = display_on ? blue  : '0;
// endLook1

    wire  [           23:0] mic;
    wire  [           15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];
        assign lab_sw   = ~ SW;

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

    `else                   // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign lab_key  = ~ KEY [w_key - 1:0];
        assign lab_sw   = ~ SW;

        assign LED      = ~ lab_led;

    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz            ),
        .w_key         (   w_lab_key          ),  // The last key is used for a reset
        .w_sw          (   w_lab_sw           ),
        .w_led         (   w_lab_led          ),
        .w_digit       (   w_lab_digit        ),
        .w_gpio        (   w_gpio             ),

        .screen_width  (   screen_width       ),
        .screen_height (   screen_height      ),

        .w_red         (   w_red              ),
        .w_green       (   w_green            ),
        .w_blue        (   w_blue             )
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
// Look2
        .x        ( x         ),
        .y        ( y         ),

        .red      ( red       ),
        .green    ( green     ),
        .blue     ( blue      ),
// end of look2
        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .mic      ( mic       ),
        .sound    ( sound     ),

        .gpio     (           )
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

    tm1638_board_controller
    # (
        .clk_mhz ( clk_mhz ),
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk        ( clk           ),
        .rst        ( rst           ),
        .hgfedcba   ( hgfedcba      ),
        .digit      ( tm_digit      ),
        .ledr       ( tm_led        ),
        .keys       ( tm_key        ),
        .sio_clk    ( GPIO_2 [2]    ),
        .sio_stb    ( GPIO_2 [3]    ),
        .sio_data   ( GPIO_2 [1]    )
    );

    //------------------------------------------------------------------------
// look3
    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz    ),
            .PIXEL_MHZ   ( pixel_mhz  )
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( VGA_HS     ),
            .vsync       ( VGA_VS     ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

    `endif
// end of look3
    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver
    # (
        .clk_mhz ( clk_mhz    )
    )
    i_microphone
    (
        .clk     ( clk        ),
        .rst     ( rst        ),
        .lr      ( GPIO_3 [1] ),
        .ws      ( GPIO_3 [2] ),
        .sck     ( GPIO_3 [3] ),
        .sd      ( GPIO_3 [0] ),
        .value   ( mic        )
    );

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
            .mclk     ( GPIO_3 [4] ),
            .bclk     ( GPIO_3 [5] ),
            .sdata    ( GPIO_3 [6] ),
            .lrclk    ( GPIO_3 [7] )
        );

    `endif

    //------------------------------------------------------------------------
//Look4
    //assign GPIO_0= { VGA_B, VGA_R };
    //assign GPIO_1 = { VGA_HS, VGA_VS, 2'bz, VGA_G };

    assign GPIO_0 = { VGA_R, VGA_B };
    assign GPIO_1 = { VGA_G, 2'b00, VGA_VS, VGA_HS  };

endmodule
