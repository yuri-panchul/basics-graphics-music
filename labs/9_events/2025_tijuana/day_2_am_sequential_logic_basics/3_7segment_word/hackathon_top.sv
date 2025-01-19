// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue
);

    //------------------------------------------------------------------------

    logic [31:0] counter;

    always_ff @ (posedge clock)
        if (reset)
            counter <= 0;
        else
            counter <= counter + 1;

    wire enable = (counter [16:0] == 0);
    // Find the number [N:0] so that your eyes cannot see LEDs moving

    //------------------------------------------------------------------------

    logic [7:0] shift_reg;

    always_ff @ (posedge clock)
      if (reset)
        shift_reg <= 1;
      else if (enable)
        shift_reg <= { shift_reg [0], shift_reg [7:1] };

    assign led = shift_reg;

    //------------------------------------------------------------------------

    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h

    typedef enum bit [7:0]
    {
        F     = 8'b1000_1110,
        P     = 8'b1100_1110,
        G     = 8'b1011_1100,
        A     = 8'b1110_1110,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

    seven_seg_encoding_e letter;

    always_comb
      case (shift_reg)
      4'b1000: letter = F;
      4'b0100: letter = P;
      4'b0010: letter = G;
      4'b0001: letter = A;
      default: letter = space;
      endcase

    assign abcdefgh = letter;
    assign digit    = shift_reg;

    // Exercise 1: Increase the frequency of enable signal
    // to the level your eyes see the letters as a solid word
    // without any blinking. What is the threshold of such frequency?

    // Exercise 2: Put your name or another word to the display.

    // Exercise 3: Comment out the "default" clause from the "case" statement
    // in the "always" block,and re-synthesize the example.
    // Are you getting any warnings or errors? Try to explain why.

endmodule
