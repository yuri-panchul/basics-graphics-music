// `define EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 10,
              w_led   = 10,
              w_digit = 6,
              w_gpio  = 36
)
(
    input                 CLOCK_50,

    input  [w_key  - 1:0] KEY,
    input  [w_sw   - 1:0] SW,
    output [w_led  - 1:0] LEDR,

    output logic    [7:0] HEX0,
    output logic    [7:0] HEX1,
    output logic    [7:0] HEX2,
    output logic    [7:0] HEX3,
    output logic    [7:0] HEX4,
    output logic    [7:0] HEX5,

    output                VGA_HS,
    output                VGA_VS,
    output [         3:0] VGA_R,
    output [         3:0] VGA_G,
    output [         3:0] VGA_B,

    inout  [w_gpio - 1:0] GPIO_0
);

    //------------------------------------------------------------------------

    wire clk = CLOCK_50;

    localparam w_top_sw = w_sw - 1;  // One sw is used as a reset

    wire                  rst = SW [w_sw - 1];
    wire [w_top_sw - 1:0] sw  = SW [w_top_sw - 1:0];

    //------------------------------------------------------------------------

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
        .clk      (   clk      ),
        .rst      (   rst      ),

        .key      ( ~ KEY      ),
        .sw       (   sw       ),

        .led      (   LEDR     ),

        .abcdefgh (   abcdefgh ),
        .digit    (   digit    ),

        .vsync    (   VGA_VS   ),
        .hsync    (   VGA_HS   ),

        .red      (   VGA_R    ),
        .green    (   VGA_G    ),
        .blue     (   VGA_B    ),

        .mic      (   mic      ),
        .gpio     (   GPIO_0     )
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

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.
        // It also does not work well with TM1638 peripheral display.

        assign HEX0 = digit [0] ? ~ hgfedcba : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba : '1;
        assign HEX4 = digit [4] ? ~ hgfedcba : '1;
        assign HEX5 = digit [5] ? ~ hgfedcba : '1;

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 } <= '1;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba;
                if (digit [1]) HEX1 <= ~ hgfedcba;
                if (digit [2]) HEX2 <= ~ hgfedcba;
                if (digit [3]) HEX3 <= ~ hgfedcba;
                if (digit [4]) HEX4 <= ~ hgfedcba;
                if (digit [5]) HEX5 <= ~ hgfedcba;
            end

    `endif

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO_0 [5] ),
        .ws    ( GPIO_0 [3] ),
        .sck   ( GPIO_0 [1] ),
        .sd    ( GPIO_0 [0] ),
        .value ( mic      )
    );

    assign GPIO_0 [12] = 1'b0;  // GND
    assign GPIO_0 [11] = 1'b1;  // VCC

endmodule
