`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 125,        // Main clk frequency
              w_key   = 4,          // Number of buttons on the board
              w_sw    = 4,          // Number of switches on the board
              w_led   = 4,          // Number of LEDs on the board
              w_digit = 0,          // 7Seg missing
              w_gpio  = 8           // Standard Pmod JE
)
(
    /* Reset - PROGB (see datasheet) */
    input                      clk_125,
    input  [w_key       - 1:0] key,
    input  [w_sw        - 1:0] sw,
    output [w_led       - 1:0] led,
    inout  [w_gpio      - 1:0] gpio_JE
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

    //------------------------------------------------------------------------

    localparam w_key_tm   = 8,
               w_led_tm   = 8,
               w_digit_tm = 8;

    //------------------------------------------------------------------------

    `ifdef DUPLICATE_TM_SIGNALS_WITH_REGULAR
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

    `ifdef CONCAT_TM_SIGNALS_AND_REGULAR
        assign key_top = {key_tm, key};
        assign {led_tm, led} = led_top;
        assign {digit_tm, digit} = digit_top;

    `elsif CONCAT_REGULAR_SIGNALS_AND_TM
        assign key_top = {key, key_tm};
        assign {led, led_tm} = led_top;
        assign {digit, digit_tm} = digit_top;

    `else  // DUPLICATE_TM_SIGNALS_WITH_REGULAR
        always_comb
        begin
            key_top = '0;
            key_top[w_key - 1:0] |= key;
            key_top[w_key_tm - 1:0] |= key_tm;
        end

        assign led = led_top[w_led - 1:0];
        assign led_tm = led_top[w_led_tm - 1:0];
        assign digit = digit_top[0:0];
        assign digit_tm = digit_top[w_digit_tm - 1:0];
    `endif

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------------

    top
    # (
        .clk_mhz  (clk_mhz),
        .w_key    (w_key_top),
        .w_sw     (w_sw_top),
        .w_led    (w_led_top),
        .w_digit  (w_digit_top),
        .w_gpio   (w_gpio)
    )
    i_top
    (
        .clk      (clk),
        .slow_clk (slow_clk),
        .rst      (rst),

        .key      (key_top),
        .sw       (sw_top),
        .led      (led_top),
        .abcdefgh (abcdefgh),
        .digit    (digit_top),

        .vsync    ( ),
        .hsync    ( ),
        .red      ( ),
        .green    ( ),
        .blue     ( ),

        .uart_rx  ( UART_RX ),
        .uart_tx  ( UART_TX ),

        .mic_ready( ),
        .mic      ( ),
        .gpio     ( )
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
        .clk_mhz  (clk_mhz),
        .w_digit  (w_digit_tm)        // fake parameter, digit count is hardcode in tm1638_board_controller
    )
    i_tm1638
    (
        .clk      (clk),
        .rst      (rst),              // Don't make reset tm1638_board_controller by it's tm_key
        .hgfedcba (hgfedcba),
        .digit    (digit_tm),
        .ledr     (led_tm),
        .keys     (key_tm),
        .sio_clk  (gpio_JE[1]),
        .sio_stb  (gpio_JE[0]),
        .sio_data (gpio_JE[2])
    );

endmodule: board_specific_top
