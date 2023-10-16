// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 12,
              w_digit = 8,
              w_gpio  = 19
)
(
    input                  CLK,

    input  [w_key   - 1:0] KEY_N,  // One key is used as a reset
    input  [w_sw    - 1:0] SW_N,
    output [w_led   - 1:0] LED_N,

    output [          7:0] ABCDEFGH_N,
    output [w_digit - 1:0] DIGIT_N,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output [          2:0] VGA_RGB,

    input                  UART_RX,

    inout  [w_gpio  - 1:0] GPIO
);

    localparam w_top_key = w_key - 1;  // One onboard key is used as a reset

    wire                   clk     = CLK;
    wire                   rst     = ~ KEY_N [w_key     - 1];
    wire [w_top_key - 1:0] top_key = ~ KEY_N [w_top_key - 1:0];

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;
    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [          3:0] red;
    wire [          3:0] green;
    wire [          3:0] blue;

    wire [         23:0] mic;

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz   ),
        .w_key   ( w_top_key ),
        .w_sw    ( w_sw      ),
        .w_led   ( w_led     ),
        .w_digit ( w_digit   ),
        .w_gpio  ( w_gpio    )
    )
    i_top
    (
        .clk      (   clk         ),
        .slow_clk (   slow_clk    ),
        .rst      (   rst         ),

        .key      (   top_key     ),
        .sw       ( ~ SW_N        ),

        .led      (   led         ),

        .abcdefgh (   abcdefgh    ),
        .digit    (   digit       ),

        .vsync    (   VGA_VSYNC   ),
        .hsync    (   VGA_HSYNC   ),

        .red      (   red         ),
        .green    (   green       ),
        .blue     (   blue        ),

        .mic      (   mic         ),
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
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [5] ),
        .ws    ( GPIO [3] ),
        .sck   ( GPIO [1] ),
        .sd    ( GPIO [0] ),
        .value ( mic      )
    );

    assign GPIO [4] = 1'b0;  // GND
    assign GPIO [2] = 1'b1;  // VCC

endmodule
