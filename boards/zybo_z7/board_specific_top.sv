`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz       = 125,        // Main clk frequency
              pixel_mhz     = 25,
              w_key         = 4,          // Number of buttons on the board
              w_sw          = 4,          // Number of switches on the board
              w_led         = 4,          // Number of LEDs on the board
              w_digit       = 0,          // 7Seg missing
              w_gpio        = 8,          // Standard Pmod JE

              screen_width  = 640,
              screen_height = 480,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    // Reset - PROGB (see datasheet)

    input                      clk_125,
    input  [w_key       - 1:0] key,
    input  [w_sw        - 1:0] sw,
    output [w_led       - 1:0] led,
    inout  [w_gpio      - 1:0] gpio_JE,

    output [w_gpio      - 1:0] jb,
    output [w_gpio      - 1:0] jc,
    output [w_gpio      - 1:0] jd
);

    wire clk = clk_125;

    //------------------------------------------------------------------------

    localparam w_sw_top = w_sw - 1;  // One sw is used as a reset

    wire rst = sw[w_sw - 1];         // Last switch is used as a reset
    wire [w_sw_top - 1:0] sw_top  = sw[w_sw_top - 1:0];

    //------------------------------------------------------------------------

    logic [              7:0] abcdefgh;
    wire  [w_digit     - 1:0] digit;

    // FIXME: Should be assigned to some GPIO!
    wire                      UART_TX;
    wire                      UART_RX = '1;
    wire [w_gpio      - 1:0]  gpio;

    // Graphics

    wire [ w_x       - 1:0] x;
    wire [ w_y       - 1:0] y;

    wire [ w_red     - 1:0] red;
    wire [ w_green   - 1:0] green;
    wire [ w_blue    - 1:0] blue;

    // Microphone and sound output

    wire [            23:0] mic;
    wire [            15:0] sound;

    //------------------------------------------------------------------------

    localparam w_key_tm   = 8,
               w_led_tm   = 8,
               w_digit_tm = 8;

    //------------------------------------------------------------------------

    `ifdef DUPLICATE_TM1638_SIGNALS_WITH_REGULAR
        localparam w_key_top   = w_key_tm   > w_key   ? w_key_tm   : w_key,
                   w_led_top   = w_led_tm   > w_led   ? w_led_tm   : w_led,
                   w_digit_top = w_digit_tm > w_digit ? w_digit_tm : w_digit;
    `else
        localparam w_key_top   = w_key_tm   + w_key,
                   w_led_top   = w_led_tm   + w_led,
                   w_digit_top = w_digit_tm + w_digit;
    `endif

    //------------------------------------------------------------------------------

        wire  [w_key_tm    - 1:0] key_tm;
        wire  [w_led_tm    - 1:0] led_tm;
        wire  [w_digit_tm  - 1:0] digit_tm;

        logic [w_key_top   - 1:0] key_top;
        wire  [w_led_top   - 1:0] led_top;
        wire  [w_digit_top - 1:0] digit_top;

    //------------------------------------------------------------------------------

    `ifdef CONCAT_TM1638_SIGNALS_AND_REGULAR
        assign key_top           = {key_tm, key};
        assign {led_tm, led}     = led_top;
        assign {digit_tm, digit} = digit_top;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM1638
        assign key_top           = {key, key_tm};
        assign {led, led_tm}     = led_top;
        assign {digit, digit_tm} = digit_top;

    `else  // DUPLICATE_TM1638_SIGNALS_WITH_REGULAR
        always_comb
        begin
            key_top = '0;
            key_top[w_key - 1:0] |= key;
            key_top[w_key_tm - 1:0] |= key_tm;
        end

        assign led      = led_top[w_led - 1:0];
        assign led_tm   = led_top[w_led_tm - 1:0];
        assign digit    = digit_top[0:0];
        assign digit_tm = digit_top[w_digit_tm - 1:0];
    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       (   clk_mhz        ),
        .w_key         (   w_key_top      ),
        .w_sw          (   w_sw_top       ),
        .w_led         (   w_led_top      ),
        .w_digit       (   w_digit_top    ),
        .w_gpio        (   w_gpio         ),

        .screen_width  (   screen_width   ),
        .screen_height (   screen_height  ),

        .w_red         (   w_red          ),
        .w_green       (   w_green        ),
        .w_blue        (   w_blue         )
    )

    i_lab_top
    (
        .clk           (   clk             ),
        .slow_clk      (   slow_clk        ),
        .rst           (   rst             ),

        .key           (   key_top         ),
        .sw            (   sw_top          ),

        .led           (   led_top         ),

        .abcdefgh      (   abcdefgh        ),
        .digit         (   digit_top       ),

        .x             (   x               ),
        .y             (   y               ),

        .red           (   red             ),
        .green         (   green           ),
        .blue          (   blue            ),

        .mic           (   mic             ),
        .sound         (   sound           ),

        .uart_rx       (   UART_RX         ),
        .uart_tx       (   UART_TX         ),

        .gpio          (   gpio            )
    );


    /***************************************************************************
     *                             module TM1638
     **************************************************************************/
    logic  [$left(abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits(abcdefgh); i++) begin
            assign hgfedcba[i] = abcdefgh [$left(abcdefgh) - i];
        end
    endgenerate


    //------------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .clk_mhz       (  clk_mhz         ),
        .w_digit       (  w_digit_tm      )        // fake parameter, digit count is hardcode in tm1638_board_controller
    )
    i_tm1638
    (
        .clk           (  clk             ),
        .rst           (  rst             ),              // Don't make reset tm1638_board_controller by it's tm_key
        .hgfedcba      (  hgfedcba        ),
        .digit         (  digit_tm        ),
        .ledr          (  led_tm          ),
        .keys          (  key_tm          ),
        .sio_clk       (  gpio_JE[1]      ),
        .sio_stb       (  gpio_JE[0]      ),
        .sio_data      (  gpio_JE[2]      )
    );


    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        assign jc[3:0] = red;
        assign jc[7:4] = green;
        assign jd[3:0] = blue;

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
            .hsync       ( jd[4]       ),
            .vsync       ( jd[5]       ),
            .display_on  (             ),
            .hpos        ( x10         ),
            .vpos        ( y10         ),
            .pixel_clk   ( VGA_CLK     )
        );

        assign VGA_BLANK_N = 1'b1;
        assign VGA_SYNC_N  = 1'b0;

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz   )
        )
        inst_audio_out
        (
            .clk     ( clk       ),
            .reset   ( rst       ),
            .data_in ( sound     ),
            .mclk    ( jb[0]     ),
            .bclk    ( jb[2]     ),
            .lrclk   ( jb[1]     ),
            .sdata   ( jb[3]     )
        );

    `endif

endmodule: board_specific_top
