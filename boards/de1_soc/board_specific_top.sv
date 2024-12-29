`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 4,
              w_sw          = 10,
              w_led         = 10,
              w_digit       = 6,
              w_gpio        = 72,     // GPIO_0[5:0] reserved for mic

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   CLOCK_50,

    input  [ w_key   - 1:0] KEY,
    input  [ w_sw    - 1:0] SW,
    output [ w_led   - 1:0] LEDR,     // The last 6 LEDR are used like a 7SEG dp

    output logic      [6:0] HEX0,     // HEX[7] aka dp doesn't connected to FPGA at DE1-SoC
    output logic      [6:0] HEX1,
    output logic      [6:0] HEX2,
    output logic      [6:0] HEX3,
    output logic      [6:0] HEX4,
    output logic      [6:0] HEX5,

    output                  VGA_CLK,  // VGA DAC input triggers CLK

    output                  VGA_HS,
    output                  VGA_VS,

    output [ w_red   - 1:0] VGA_R,
    output [ w_green - 1:0] VGA_G,
    output [ w_blue  - 1:0] VGA_B,
    output                  VGA_BLANK_N,
    output                  VGA_SYNC_N,

    inout                   AUD_ADCLRCK,
    input                   AUD_ADCDAT,
    inout                   AUD_BCLK,
    inout                   AUD_DACLRCK,
    output                  AUD_DACDAT,
    output                  AUD_XCK,

    output                  FPGA_I2C_SCLK,
    inout                   FPGA_I2C_SDAT,

    inout  [        35:0]   GPIO_0,
    inout  [        35:0]   GPIO_1
);

    //------------------------------------------------------------------------

    // The last 6 LEDR are used like a 7SEG dp
    // One sw is used as a reset

    localparam w_lab_led = w_led - w_digit,
               w_lab_sw  = w_sw  - 1;

    //------------------------------------------------------------------------

    wire                     clk     = CLOCK_50;

    wire                     rst     = SW [w_lab_sw];
    wire  [ w_lab_sw  - 1:0] lab_sw  = SW [w_lab_sw - 1:0];

    //------------------------------------------------------------------------

    wire  [ w_lab_led - 1:0] lab_led;

    // A dynamic seven-segment display

    wire  [             7:0] abcdefgh;
    wire  [ w_digit   - 1:0] digit;

    // Graphics

    wire  [ w_x       - 1:0] x;
    wire  [ w_y       - 1:0] y;

    // Microphone and sound output

    wire [             23:0] mic;
    wire [             15:0] sound;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz              ),
        .w_key         ( w_key                ),
        .w_sw          ( w_lab_sw             ),
        .w_led         ( w_lab_led            ),  // The last 6 LEDR are used like a 7SEG dp
        .w_digit       ( w_digit              ),
        .w_gpio        ( w_gpio               ),  // GPIO_0[5:0] reserved for mic

        .screen_width  ( screen_width         ),
        .screen_height ( screen_height        ),

        .w_red         ( w_red                ),
        .w_green       ( w_green              ),
        .w_blue        ( w_blue               )
    )
    i_lab_top
    (
        .clk           (   clk                ),
        .slow_clk      (   slow_clk           ),
        .rst           (   rst                ),

        .key           ( ~ KEY                ),
        .sw            (   lab_sw             ),

        .led           (   lab_led            ),

        .abcdefgh      (   abcdefgh           ),
        .digit         (   digit              ),

        .x             (   x                  ),
        .y             (   y                  ),

        .red           (   VGA_R              ),
        .green         (   VGA_G              ),
        .blue          (   VGA_B              ),

        .mic           (   mic                ),
        .sound         (   sound              ),

        // TODO: .qsf file is not consistent with the reference file from the vendor
        // TODO: Find the correct file and fix the UART signals

        .uart_rx       (                      ),
        .uart_tx       (                      ),

        .gpio          (   { GPIO_0, GPIO_1 } )
    );

    //------------------------------------------------------------------------

    assign LEDR [w_lab_led - 1:0] = lab_led;

    //------------------------------------------------------------------------

    wire  [$left (abcdefgh):0] hgfedcba;
    logic [$left    (digit):0] dp;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_ON_STATIC_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.

        // inverted logic

        assign HEX0 = digit [0] ? ~ hgfedcba [$left (HEX0):0] : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba [$left (HEX1):0] : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba [$left (HEX2):0] : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba [$left (HEX3):0] : '1;
        assign HEX4 = digit [4] ? ~ hgfedcba [$left (HEX4):0] : '1;
        assign HEX5 = digit [5] ? ~ hgfedcba [$left (HEX5):0] : '1;

        // positive logic

        always_comb
            for (int i = 0; i < w_digit; i ++)
                dp [i] = digit [i] ? hgfedcba [$left (HEX0) + 1] : '0;

    `else

        always_ff @ (posedge clk or posedge rst)
        begin
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 } <= '1;
                dp <= '0;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba [$left (HEX0):0];
                if (digit [1]) HEX1 <= ~ hgfedcba [$left (HEX1):0];
                if (digit [2]) HEX2 <= ~ hgfedcba [$left (HEX2):0];
                if (digit [3]) HEX3 <= ~ hgfedcba [$left (HEX3):0];
                if (digit [4]) HEX4 <= ~ hgfedcba [$left (HEX4):0];
                if (digit [5]) HEX5 <= ~ hgfedcba [$left (HEX5):0];

                for (int i = 0; i < w_digit; i ++)
                    if (digit [i])
                        dp [i] <=  hgfedcba [$left (HEX0) + 1];
            end
        end

    `endif

    assign LEDR [w_led - 1:w_lab_led] = dp;  // The last 6 LEDR are used like a 7SEG dp

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
            .hsync       ( VGA_HS      ),
            .vsync       ( VGA_VS      ),
            .display_on  ( VGA_BLANK_N ),
            .hpos        ( x10         ),
            .vpos        ( y10         ),
            .pixel_clk   ( VGA_CLK     )
        );

        assign VGA_SYNC_N  = 1'b0;

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

        inmp441_mic_i2s_receiver
        # (
            .clk_mhz ( clk_mhz    )
        )
        i_microphone
        (
            .clk     ( clk        ),
            .rst     ( rst        ),
            .lr      ( GPIO_0 [0] ),  // JP1 pin 1
            .ws      ( GPIO_0 [2] ),  // JP1 pin 3
            .sck     ( GPIO_0 [4] ),  // JP1 pin 5
            .sd      ( GPIO_0 [5] ),  // JP1 pin 6
            .value   ( mic        )
        );

        assign GPIO_0 [1] = 1'b0;  // GND - JP1 pin 2
        assign GPIO_0 [3] = 1'b1;  // VCC - JP1 pin 4

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        // DE1-SoC onboard audio codec: WM8731
        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz      )
        )
        i_audio_out
        (
            .clk     ( clk          ),
            .reset   ( rst          ),
            .data_in ( sound        ),
            .mclk    ( AUD_XCK      ),
            .bclk    ( AUD_BCLK     ),
            .lrclk   ( AUD_DACLRCK  ),
            .sdata   ( AUD_DACDAT   )
        );

        // The audio codec configuration
        I2C_AUDIO_Config
        i_i2c_codec_conf (
            .iCLK    (clk),
            .iRST_N  (~rst),
            .I2C_SCLK(FPGA_I2C_SCLK),
            .I2C_SDAT(FPGA_I2C_SDAT),
            .READY   ()
        );

    `endif

endmodule
