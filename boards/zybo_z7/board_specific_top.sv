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
    input         CLK125MHZ,
    /* Reset - PROGB (see datasheet) */

    /* 4 Buttons */
    input  [3:0]  BTN,

    /* 4 Switches */
    input  [3:0]  SW,

    /* 4 LEDs */
    output [3:0]  LED,

    /* RGB LED_5 */
    output        LED5_R,
    output        LED5_G,
    output        LED5_B,
    /* RGB LED_6 */
    output        LED6_R,
    output        LED6_G,
    output        LED6_B
);

    //--------------------------------------------------------------------------

    wire clk =   CLK125MHZ;

    //--------------------------------------------------------------------------

    assign LED5_R = 1'b0;
    assign LED5_G = 1'b0;
    assign LED5_B = 1'b0;
    assign LED6_R = 1'b0;
    assign LED6_G = 1'b0;
    assign LED6_B = 1'b0;

    //--------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz ),
        .w_key   ( w_key   ),
        .w_sw    ( w_sw    ),
        .w_led   ( w_led   ),
        .w_digit ( w_digit ),
        .w_gpio  ( w_gpio  )
    )
    i_top
    (
        .clk      ( clk    ),
        .rst      (        ),
        .key      ( BTN    ),
        .sw       ( SW     ),

        .led      ( LED    ),

        .abcdefgh (        ),

        .digit    (        ),

        .vsync    (        ),
        .hsync    (        ),

        .red      (        ),
        .green    (        ),
        .blue     (        ),

        .mic      (        ),
        .gpio     (        )
    );

endmodule
