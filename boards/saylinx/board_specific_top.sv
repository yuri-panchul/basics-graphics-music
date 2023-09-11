module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 3,
              w_sw    = 3,
              w_led   = 4,
              w_digit = 8,
              w_gpio  = 2
)
(
    input                  CLK,
    input                  RST_N,

    input                  KEY2,
    input                  KEY3,
    input                  KEY4,

    output [w_led   - 1:0] LED,

    output [          7:0] SEG_DATA,
    output [w_digit - 1:0] SEG_SEL,

    output                 VGA_OUT_HS,
    output                 VGA_OUT_VS,

    output [          4:0] VGA_OUT_R,
    output [          5:0] VGA_OUT_G,
    output [          4:0] VGA_OUT_B,

    input                  UART_RXD,

    inout  [w_gpio  - 1:0] GPIO
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
