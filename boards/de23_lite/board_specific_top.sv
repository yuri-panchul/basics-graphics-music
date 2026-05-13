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
              w_gpio        = 36,

              // GPIO_D[5:0] are reserved for INMP 441 I2S microphone.
              // GPIO_D [11], [13], [15], [17] are reserved for I2S audio.

              screen_width  = 640,
              screen_height = 480,

              w_red         = 8,
              w_green       = 8,
              w_blue        = 8,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                       CLOCK1_50,

    input        [w_key  - 1:0] KEY,
    input        [w_sw   - 1:0] SW,
    output logic [w_led  - 1:0] LEDR,             // LEDR onboard, inverted logic
                                                  // The last w_digit LEDR are used like a 7SEG dp

    inout                       HDMI_I2S0,
    inout                       HDMI_LRCLK,
    inout                       HDMI_MCLK,
    inout                       HDMI_SCLK,
    output                      HDMI_TX_CLK,
    output                      HDMI_TX_DE,
    output       [        23:0] HDMI_TX_D,
    output                      HDMI_TX_HS,
    input                       HDMI_TX_INT,
    output                      HDMI_TX_VS,

    output logic [         6:0] HEX0,             // HEX[7] aka dp are not connected to FPGA at "DE23-Lite"
    output logic [         6:0] HEX1,
    output logic [         6:0] HEX2,
    output logic [         6:0] HEX3,
    output logic [         6:0] HEX4,
    output logic [         6:0] HEX5,

    inout                       I2C_SCL,
    inout                       I2C_SDA,

    input                       UART_RX,

    inout        [w_gpio - 1:0] GPIO_D
);

    //------------------------------------------------------------------------

    localparam w_lab_sw  = w_sw  - 1;             // One onboard SW is used as a reset
    localparam w_lab_led = w_led - w_digit;       // The last w_digit LEDR are used like a 7SEG dp

    //------------------------------------------------------------------------

    wire                  clk    = CLOCK1_50;

    wire                  rst    = SW [w_lab_sw];

    // Keys, switches, LEDs

    wire [ w_key     - 1:0] lab_key = ~ KEY;
    wire [ w_lab_sw  - 1:0] lab_sw  =   SW [w_lab_sw - 1:0];
    wire [ w_lab_led - 1:0] lab_led;

    // A dynamic seven-segment display

    wire [             7:0] abcdefgh;
    wire [ w_digit   - 1:0] digit;

    // Graphics

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    wire                    vs, hs;

    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;

    // Microphone, sound output and UART

    wire [            23:0] mic;
    wire [            15:0] sound;

    wire                    UART_TX;                // FIXME: Should be assigned to some GPIO!

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz       ),
        .w_key         (   w_key         ),
        .w_sw          (   w_lab_sw      ),
        .w_led         (   w_lab_led     ),
        .w_digit       (   w_digit       ),
        .w_gpio        (   w_gpio        ),

        .screen_width  (   screen_width  ),
        .screen_height (   screen_height ),

        .w_red         (   w_red         ),
        .w_green       (   w_green       ),
        .w_blue        (   w_blue        )
    )
    i_lab_top
    (
        .clk           (   clk           ),
        .slow_clk      (   slow_clk      ),
        .rst           (   rst           ),

        .key           (   lab_key       ),
        .sw            (   lab_sw        ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         ),

        .x             (   x             ),
        .y             (   y             ),

        .red           (   red           ),
        .green         (   green         ),
        .blue          (   blue          ),

        .mic           (   mic           ),
        .sound         (   sound         ),

        .uart_rx       (   UART_RX       ),
        .uart_tx       (   UART_TX       ),

        .gpio          (   GPIO_D        )
    );

    //------------------------------------------------------------------------

    // The last w_digit LEDR are used like a 7SEG dp

    assign LEDR [w_lab_led - 1:0] = ~ lab_led;    // inverted logic

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

        always_comb
            for (int i = 0; i < w_digit; i ++)
                dp [i] = digit [i] ? ~ hgfedcba [$left (HEX0) + 1] : '1;

    `else

        always_ff @ (posedge clk or posedge rst)
        begin
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 } <= '1;
                dp <= '1;
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
                        dp [i] <= ~ hgfedcba [$left (HEX0) + 1];
            end
        end

    `endif

    assign LEDR [w_led - 1:w_lab_led] = dp;  // The last w_digit LEDR are used like a 7SEG dp

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .H_DISPLAY   ( screen_width  ),
            .V_DISPLAY   ( screen_height ),
            .CLK_MHZ     ( clk_mhz       ),
            .PIXEL_MHZ   ( pixel_mhz     )
        )
        i_vga
        (
            .clk         ( clk           ),
            .rst         ( rst           ),
            .hsync       ( hs            ),
            .vsync       ( vs            ),
            .display_on  ( display_on    ),
            .hpos        ( x10           ),
            .vpos        ( y10           ),
            .pixel_clk   ( pixel_clk     )
        );

        // HDMI Video out
        wire       pixel_clk;
        wire       display_on;

        assign HDMI_TX_CLK      = pixel_clk;
        assign HDMI_TX_D        = {{red,{(8 - w_red){1'b1}}},{green,{(8 - w_green){1'b1}}},{blue,{(8 - w_blue){1'b1}}}}; // eight bit color is max
        assign HDMI_TX_DE       = display_on;
        assign HDMI_TX_HS       = hs;
        assign HDMI_TX_VS       = vs;

        // HDMI audio
        assign HDMI_I2S0        = 1'b0;
        assign HDMI_LRCLK       = 1'b0;
        assign HDMI_MCLK        = 1'b0;
        assign HDMI_SCLK        = 1'b0;

        // HDMI transmitter configuration
        `ifndef I2C_INSTANTIATED
            `define I2C_INSTANTIATED
            I2C_HDMI_Config i_i2c_hdmi_conf (
                .iCLK        ( clk         ),
                .iRST_N      ( ~rst        ),
                .I2C_SCLK    ( I2C_SCL     ),
                .I2C_SDAT    ( I2C_SDA     ),
                .HDMI_TX_INT ( HDMI_TX_INT ),
                .READY       (             )
            );
        `endif

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
            .lr      ( GPIO_D [0] ),  // JP1 pin 1
            .ws      ( GPIO_D [2] ),  // JP1 pin 3
            .sck     ( GPIO_D [4] ),  // JP1 pin 5
            .sd      ( GPIO_D [5] ),  // JP1 pin 6
            .value   ( mic        )
        );

        assign GPIO_D [1] = 1'b0;   // GND - JP1 pin 2 (7.5mA MAX)
        assign GPIO_D [3] = 1'b1;   // VCC - JP1 pin 4 (7.5mA MAX)

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz     )
        )
        inst_audio_out
        (
            .clk     ( clk         ),
            .reset   ( rst         ),
            .data_in ( sound       ),
            .mclk    ( GPIO_D [17] ), // JP1 pin 20
            .bclk    ( GPIO_D [15] ), // JP1 pin 18
            .lrclk   ( GPIO_D [11] ), // JP1 pin 14
            .sdata   ( GPIO_D [13] )  // JP1 pin 16
        );                            // JP1 pin 12 - GND, pin 29 - VCC 3.3V (1.5A MAX)

    `endif

endmodule
