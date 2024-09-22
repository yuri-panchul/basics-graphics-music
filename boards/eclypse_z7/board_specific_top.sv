`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 125,
              pixel_mhz     = 25,

              w_key         = 2,
              w_sw          = 0,
              w_led         = 6,
              w_digit       = 0,
              w_gpio        = 0,

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                clk,
    input  [w_key - 1:0] btn,

    output               led0_b, 
	output               led0_g,
    output               led0_r,

    output               led1_b,
    output               led1_g,
    output               led1_r


);

    //------------------------------------------------------------------------

    wire rst = ~ btn [0];

    wire [w_led - 1:0] lab_led;
    assign { led0_b, led0_g, led0_r, led1_b, led1_g, led1_r } = lab_led;

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
        .w_digit       ( 1 /* w_digit */       ),
        .w_gpio        ( 1 /* w_gpio  */       ),

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

        .key           ( ~ btn          ),
        .sw            ( ~ btn          ),

        .led           ( lab_led        ),

        .abcdefgh      (        ),
        .digit         (          ),

        .x             (             ),
        .y             (            ),

        .red           (          ),
        .green         (          ),
        .blue          (          ),

        .mic           (           ),
        .sound         (           ),

        .uart_rx       (     ),
        .uart_tx       (       ),

        .gpio          (                )
    );

    //------------------------------------------------------------------------

    `ifdef UNDEFINED

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
            .clk     ( clk     ),
            .rst     ( rst     ),
            .lr      ( JD [9]  ),
            .ws      ( JD [8]  ),
            .sck     ( JD [7]  ),
            .sd      ( JD [1]  ),
            .value   ( mic     )
        );

        assign JD [3] = 1'b0;  // GND
        assign JD [2] = 1'b1;  // VCC
    
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

            .mclk    ( JC [ 7]  ),
            .bclk    ( JC [ 8]  ),
            .sdata   ( JC [ 9]  ),
            .lrclk   ( JC [10]  )
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

            .mclk    ( JB [9]  ),
            .bclk    ( JB [4]  ),
            .sdata   ( JB [2]  ),
            .lrclk   ( JB [1]  )
        );

    `endif

    `endif

endmodule
