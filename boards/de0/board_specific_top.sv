// `define EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

module board_specific_top
# (
    parameter clk_mhz = 50,
              w_key   = 3,
              w_sw    = 10, // One sw is used as a reset
              w_led   = 10,
              w_digit = 4,
              w_gpio  = 31
)
(
    input                CLOCK_50,

    input  [w_key - 1:0] BUTTON,
    input  [w_sw  - 1:0] SW,
    output [w_led - 1:0] LEDG,

    output logic [  6:0] HEX0_D,
    output logic [  6:0] HEX1_D,
    output logic [  6:0] HEX2_D,
    output logic [  6:0] HEX3_D,

    output               VGA_HS,
    output               VGA_VS,
    output [        3:0] VGA_R,
    output [        3:0] VGA_G,
    output [        3:0] VGA_B,

    inout  [       35:0] GPIO0_D,
    inout  [       35:0] GPIO1_D
);

    //------------------------------------------------------------------------

    wire              clk = CLOCK_50;

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
        .clk_mhz ( clk_mhz  ),
        .w_key   ( w_key    ),
        .w_sw    ( w_top_sw ),
        .w_led   ( w_led    ),
        .w_digit ( w_digit  ),
        .w_gpio  ( w_gpio   )
    )
    i_top
    (
        .clk      (   clk                ),
        .rst      (   rst                ),

        .key      ( ~ BUTTON             ),
        .sw       (   sw [w_top_sw - 1:0]    ),

        .led      (   LEDG               ),

        .abcdefgh (   abcdefgh           ),
        .digit    (   digit              ),

        .vsync    (   VGA_VS             ),
        .hsync    (   VGA_HS             ),

        .red      (   VGA_R              ),
        .green    (   VGA_G              ),
        .blue     (   VGA_B              ),

        .mic      (   mic                ),
        .gpio     (   { GPIO1_D, GPIO0_D } )
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

        assign HEX0_D = digit [0] ? ~ hgfedcba [$left (HEX0_D):0] : '1;
        assign HEX1_D = digit [1] ? ~ hgfedcba [$left (HEX1_D):0] : '1;
        assign HEX2_D = digit [2] ? ~ hgfedcba [$left (HEX2_D):0] : '1;
        assign HEX3_D = digit [3] ? ~ hgfedcba [$left (HEX3_D):0] : '1;

    `else

        always_ff @ (posedge clk or posedge rst)
            if (rst)
            begin
                { HEX0_D, HEX1_D, HEX2_D, HEX3_D } <= '1;
            end
            else
            begin
                if (digit [0]) HEX0_D <= ~ hgfedcba [$left (HEX0_D):0];
                if (digit [1]) HEX1_D <= ~ hgfedcba [$left (HEX1_D):0];
                if (digit [2]) HEX2_D <= ~ hgfedcba [$left (HEX2_D):0];
                if (digit [3]) HEX3_D <= ~ hgfedcba [$left (HEX3_D):0];
            end

    `endif

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   (   CLOCK_50   ),
        .rst   (   rst        ),
        .lr    (   GPIO0_D [5] ),
        .ws    (   GPIO0_D [3] ),
        .sck   (   GPIO0_D [1] ),
        .sd    (   GPIO0_D [0] ),
        .value (   mic        )
    );

    assign GPIO0_D [4] = 1'b0;  // GND
    assign GPIO0_D [2] = 1'b1;  // VCC

endmodule
