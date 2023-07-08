module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 10,
              w_led   = 18,
              w_digit = 4,
              w_gpio  = 22
)
(
    input                 CLOCK_50_B8A,
    input                 CPU_RESET_n,

    input  [w_key  - 1:0] KEY,
    input  [w_sw   - 1:0] SW,
    output [         9:0] LEDR,
    output [         7:0] LEDG,

    output [         6:0] HEX0,
    output [         6:0] HEX1,
    output [         6:0] HEX2,
    output [         6:0] HEX3,

    input                 UART_RX,

    inout  [w_gpio - 1:0] GPIO
);

    //------------------------------------------------------------------------

    wire [w_led   - 1:0] led;

    assign { LEDR, LEDG } = led;

    wire [          7:0] abcdefgh;
    wire [w_digit - 1:0] digit;

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
        .clk      (   CLOCK_50_B8A ),
        .rst      ( ~ CPU_RESET_n  ),

        .key      ( ~ KEY          ),
        .sw       (   SW           ),

        .led      (   led          ),

        .abcdefgh (   abcdefgh     ),
        .digit    (   digit        ),

        .vsync    (                ),
        .hsync    (                ),

        .red      (                ),
        .green    (                ),
        .blue     (                ),

        .mic      (   mic          ),
        .gpio     (   GPIO         )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    assign HEX0 = digit [0] ? ~ hgfedcba [$left (HEX0):0] : '1;
    assign HEX1 = digit [1] ? ~ hgfedcba [$left (HEX1):0] : '1;
    assign HEX2 = digit [2] ? ~ hgfedcba [$left (HEX2):0] : '1;
    assign HEX3 = digit [3] ? ~ hgfedcba [$left (HEX3):0] : '1;

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   (   CLOCK_50_B8A ),
        .rst   ( ~ CPU_RESET_n  ),
        .lr    (   GPIO [5]     ),
        .ws    (   GPIO [3]     ),
        .sck   (   GPIO [1]     ),
        .sd    (   GPIO [0]     ),
        .value (   mic          )
    );

    assign GPIO [4] = 1'b0;  // GND
    assign GPIO [2] = 1'b1;  // VCC

endmodule
