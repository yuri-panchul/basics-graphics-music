`include "config.svh"
`include "lab_specific_board_config.svh"

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 1,
              w_sw    = 0,
              w_led   = 1,
              w_digit = 3,
              w_gpio  = 36 - 3 + 1  // from GPIO_J12[36] till GPIO_J12[3]
)
(
    input                     CLK,
    input                     KEY,
    output                    LED,

    output [             7:0] ABCDEFGH_N,
    output [w_digit    - 1:0] DIGIT_N,

    output                    VGA_HSYNC,
    output                    VGA_VSYNC,

    output [             4:0] VGA_RED,
    output [             5:0] VGA_GREEN,
    output [             4:0] VGA_BLUE,

    input                     UART_RX,

    inout  [w_gpio + 3 - 1:3] GPIO_J12
);

    //------------------------------------------------------------------------

    wire                 clk = CLK;
    wire                 rst = ~ KEY;
    wire                 led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [          3:0] red, green, blue;
    wire [         23:0] mic;

    // FIXME: Should be assigned to some GPIO!
    wire                 UART_TX;

    //------------------------------------------------------------------------

    assign ABCDEFGH_N = ~ abcdefgh;
    assign DIGIT_N    = ~ digit;

    assign VGA_RED    = {            red   [3], red   };
    assign VGA_GREEN  = { green [3], green [3], green };
    assign VGA_BLUE   = {            blue  [3], blue  };

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz  ( clk_mhz   ),
        .w_key    ( 1         ),  // There are no keys
        .w_sw     ( 1         ),  // There are no switches
        .w_led    ( w_led     ),
        .w_digit  ( w_digit   ),
        .w_gpio   ( w_gpio    )
    )
    i_lab_top
    (
        .clk      ( clk       ),
        .slow_clk ( slow_clk  ),
        .rst      ( rst       ),

        .key      ( '0        ),
        .sw       ( '0        ),

        .led      ( LED       ),

        .abcdefgh ( abcdefgh  ),
        .digit    ( digit     ),

        .vsync    ( VGA_VSYNC ),
        .hsync    ( VGA_HSYNC ),

        .red      ( red       ),
        .green    ( green     ),
        .blue     ( blue      ),

        .uart_rx  ( UART_RX   ),
        .uart_tx  ( UART_TX   ),

        .mic      ( mic       ),

        .gpio     ( GPIO_J12  )
    );

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk          ),
        .rst   ( rst          ),
        .lr    ( GPIO_J12 [8] ),
        .ws    ( GPIO_J12 [6] ),
        .sck   ( GPIO_J12 [4] ),
        .sd    ( GPIO_J12 [3] ),
        .value ( mic          )
    );

    assign GPIO_J12 [7] = 1'b0;  // GND
    assign GPIO_J12 [5] = 1'b1;  // VCC

endmodule
