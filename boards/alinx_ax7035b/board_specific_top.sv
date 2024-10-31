`include "config.svh"
`include "lab_specific_board_config.svh"
`include "swap_bits.svh"

`ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
`undef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
`endif

`ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
`undef INSTANTIATE_MICROPHONE_INTERFACE_MODULE
`endif

`ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
`undef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
`endif

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 0,
              w_led         = 4,
              w_digit       = 6,
              w_gpio        = 68,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   sys_clk,
    input                   rst_n,

    input  [w_key    - 1:0] key_in,
    output [w_led    - 1:0] led,

    output [           7:0] SMG_Data,
    output [w_digit  - 1:0] Scan_Sig,

//    output                  TMDS_clk_n,
//    output                  TMDS_clk_p,
//    output [           2:0] TMDS_data_n,
//    output [           2:0] TMDS_data_p,
//    output [           0:0] HDMI_OEN,

    input                   uart_rx,
    output                  uart_tx

    // TODO
    // inout [3:36] j9,
    // inout [3:36] j10
);

    // TODO

    wire [3:36] j9;
    wire [3:36] j10;

    //------------------------------------------------------------------------

    // Clock and reset

    wire clk =   sys_clk;
    wire rst = ~ rst_n;

    // Keys and LEDs

    wire [w_key - 1:0] lab_key;
    wire [w_led - 1:0] lab_led;

    `SWAP_BITS ( lab_key , ~ key_in  );
    `SWAP_BITS ( led     , ~ lab_led );

    // Seven-segment display

    wire [7:0] abcdefgh;
    wire [7:0] digit;     

    `SWAP_BITS (SMG_Data, ~ abcdefgh);
    assign Scan_Sig = ~ digit;

    // Graphics

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire [w_red   - 1:0] red;
    wire [w_green - 1:0] green;
    wire [w_blue  - 1:0] blue;

    // REMOVE assign vgaRed   = display_on ? red   : '0;
    // REMOVE assign vgaGreen = display_on ? green : '0;
    // REMOVE assign vgaBlue  = display_on ? blue  : '0;

    // Sound

    wire [         23:0] mic;
    wire [         15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz        ),
        .w_key         ( w_key          ),
        .w_sw          ( w_key          ),
        .w_led         ( w_led          ),
        .w_digit       ( w_digit        ),
        .w_gpio        ( w_gpio         ),

        .screen_width  ( screen_width   ),
        .screen_height ( screen_height  ),

        .w_red         ( w_red          ),
        .w_green       ( w_green        ),
        .w_blue        ( w_blue         )
    )
    i_lab_top
    (
        .clk           ( clk            ),
        .slow_clk      ( slow_clk       ),
        .rst           ( rst            ),

        .key           ( lab_key        ),
        .sw            ( lab_key        ),

        .led           ( lab_led        ),

        .abcdefgh      ( abcdefgh       ),
        .digit         ( digit          ),

        .x             ( x              ),
        .y             ( y              ),

        .red           ( red            ),
        .green         ( green          ),
        .blue          ( blue           ),

        .mic           ( mic            ),
        .sound         ( sound          ),

        .uart_rx       ( uart_rx        ),
        .uart_tx       ( uart_tx        ),

        .gpio          ( { j9, j10 }    )
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
            .clk         ( clk         ),
            .rst         ( rst         ),
            .vsync       ( Vsync       ),
            .hsync       ( Hsync       ),
            .display_on  ( display_on  ),
            .hpos        ( x10         ),
            .vpos        ( y10         ),
            .pixel_clk   (             )
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
            .clk     ( clk    ),
            .rst     ( rst    ),
            .lr      ( JA [6] ),
            .ws      ( JA [5] ),
            .sck     ( JA [4] ),
            .sd      ( JA [0] ),
            .value   ( mic    )
        );

        assign JA [2] = 1'b0;  // GND - JA pin 3
        assign JA [1] = 1'b1;  // VCC - JA pin 2

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz )
        )
        inst_pcm5102
        (
            .clk     ( clk     ),
            .reset   ( rst     ),
            .data_in ( sound   ),

            .mclk    ( JC [4]  ),
            .bclk    ( JC [5]  ),
            .sdata   ( JC [6]  ),
            .lrclk   ( JC [7]  )
        );

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz )
        )
        inst_pmod_amp3
        (
            .clk     ( clk     ),
            .reset   ( rst     ),
            .data_in ( sound   ),

            .mclk    ( JB [6]  ),
            .bclk    ( JB [3]  ),
            .sdata   ( JB [1]  ),
            .lrclk   ( JB [0]  )
        );

    `endif

endmodule
