module board_specific_top
# (
    parameter clk_mhz   = 50,
              w_key     = 8,
              w_sw      = 8,
              w_led     = 16,
              w_digit   = 6,
              w_gpio_j7 = 36, // [3..38]
              w_gpio_p1 = 21, // [2..22]
              w_gpio_p2 = 21  // [2..22] TODO do we need to include buzzer and EEPROM?
)
(
    input                    CLK,
    input                    RST_N,

    input  [w_key     - 1:0] KEY_N,
    input  [w_sw      - 1:0] SW_N,

    output [w_led     - 1:0] LED_N,

    output [            7:0] ABCDEFGH_N,
    output [w_digit   - 1:0] DIGIT_N,

    input                    UART_RX,
    output                   UART_TX,

    inout  [w_gpio_j7 - 1:0] GPIO_J7,
    inout  [w_gpio_p1 - 1:0] GPIO_P1,
    inout  [w_gpio_p2 - 1:0] GPIO_P2
);

    //------------------------------------------------------------------------

    wire                 rst = ~ RST_N;
    wire [w_key   - 1:0] key = ~ { KEY2, KEY3, KEY4 };

    wire [w_led   - 1:0] led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

    wire [          3:0] red, green, blue;
    wire [         23:0] mic;

    //------------------------------------------------------------------------

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
        .clk      ( CLK        ),
        .rst      ( rst        ),

        .key      ( key        ),
        .sw       ( key        ),

        .led      ( LED        ),

        .abcdefgh ( abcdefgh   ),
        .digit    ( digit      ),

        .vsync    ( VGA_OUT_VS ),
        .hsync    ( VGA_OUT_HS ),

        .red      ( red       ),
        .green    ( green     ),
        .blue     ( blue      ),

        .mic      ( mic       ),


        .gpio ( GPIO )

    );

    //------------------------------------------------------------------------

    assign SEG_DATA  = ~ abcdefgh;
    assign SEG_SEL   = ~ digit;

    assign VGA_OUT_R = {            red   [3], red   };
    assign VGA_OUT_G = { green [3], green [3], green };
    assign VGA_OUT_B = {            blue  [3], blue  };

    /*
    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( CLK      ),
        .rst   ( rst      ),
        .lr    ( GPIO [5] ),
        .ws    ( GPIO [3] ),
        .sck   ( GPIO [1] ),
        .sd    ( GPIO [0] ),
        .value ( mic      )
    );

    assign GPIO [4] = 1'b0;  // GND
    assign GPIO [2] = 1'b1;  // VCC
    */

endmodule
