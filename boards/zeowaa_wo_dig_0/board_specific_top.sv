// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 3,
              w_sw    = 8,
              w_led   = 12,
              w_digit = 8,
              w_gpio  = 19
)
(
    input                    CLK,

    input  [w_key + 1 - 1:0] KEY_N,  // One key is used as a reset
    input  [w_sw      - 1:0] SW_N,
    output [w_led     - 1:0] LED_N,

    output [            7:0] ABCDEFGH_N,
    output [w_digit   - 1:0] DIGIT_N,

    output                   VGA_HSYNC,
    output                   VGA_VSYNC,
    output [            2:0] VGA_RGB,

    input                    UART_RX,

    inout  [w_gpio    - 1:0] GPIO
);

    wire clk = CLK;
    wire rst = ~ KEY_N [3];

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;
    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [          3:0] red;
    wire [          3:0] green;
    wire [          3:0] blue;

    wire [         23:0] mic;
    wire                 mic_ready;

    // FIXME: Should be assigned to some GPIO!
    wire                 UART_TX;

    wire [         15:0] sound;

    //------------------------------------------------------------------------

    // This logic is necessary to compensate the defective board

    localparam w_top_digit = w_digit - 1;  // The right digit is not working on this board
    wire [w_top_digit - 1:0] top_digit;

    assign digit = { top_digit, 1'b0 };

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz     ),
        .w_key   ( w_key       ),
        .w_sw    ( w_sw        ),
        .w_led   ( w_led       ),
        .w_digit ( w_top_digit ),  // Note top_digit, not digit
        .w_gpio  ( w_gpio      )
    )
    i_top
    (
        .clk      (   clk         ),
        .slow_clk (   slow_clk    ),
        .rst      (   rst         ),

        .key      ( ~ KEY_N [2:0] ),
        .sw       ( ~ SW_N        ),

        .led      (   led         ),

        .abcdefgh (   abcdefgh    ),
        .digit    (   top_digit   ),  // Note top_digit, not digit

        .vsync    (   VGA_VSYNC   ),
        .hsync    (   VGA_HSYNC   ),

        .red      (   red         ),
        .green    (   green       ),
        .blue     (   blue        ),

        .uart_rx  (   UART_RX     ),
        .uart_tx  (   UART_TX     ),

        .mic_ready(   mic_ready   ),
        .mic      (   mic         ),
        .sound    (   sound       ),

        .gpio     (   GPIO        )
    );

    //------------------------------------------------------------------------

    assign LED_N      = ~ led;

    assign ABCDEFGH_N = ~ abcdefgh;
    assign DIGIT_N    = ~ digit;

    assign VGA_RGB    = { | red, | green, | blue };

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk       ),
        .rst   ( rst       ),
        .lr    ( GPIO [5]  ), // P33
        .ws    ( GPIO [3]  ), // P31
        .sck   ( GPIO [1]  ), // P28
        .sd    ( GPIO [0]  ), // P30
        .ready ( mic_ready ),
        .value ( mic       )
    );

    assign GPIO [4] = 1'b0;  // P34 - GND
    assign GPIO [2] = 1'b1;  // P32 - VCC

    //------------------------------------------------------------------------

    i2s_audio_out
    # (
        .clk_mhz ( clk_mhz     )
    )
    o_audio
    (
        .clk     ( clk       ),
        .reset   ( rst       ),
        .data_in ( sound     ),
        .mclk    ( GPIO [14] ), // P52
        .bclk    ( GPIO [12] ), // P49
        .lrclk   ( GPIO [8]  ), // P42
        .sdata   ( GPIO [10] )  // P44
    );                          // GND
                                // J4 Pin 2 - VCC 3.3V (30-45 mA)

endmodule
