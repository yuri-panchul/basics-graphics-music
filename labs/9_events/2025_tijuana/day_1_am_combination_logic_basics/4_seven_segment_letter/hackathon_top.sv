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
    //   --a--       --1--
    //  |     |     |      
    //  f     b     1     0
    //  |     |     |      
    //   --g--       --1--
    //  |     |     |      
    //  e     c     1     0
    //  |     |     |      
    //   --d--  h      0    0

    typedef enum bit [7:0]
    {
        //         abcd efgh
        F     = 8'b1000_1110,  // This means "8-bit binary number"
        P     = 8'b1100_1110,
        G     = 8'b1011_1100,
        A     = 8'b1110_1110,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

    assign abcdefgh = key [0] ? P : F;
    assign digit    = key [1] ? 2'b10 : 2'b01;

    // Exercise 1: Display the first letters
    // of your first name and last name instead.

    // assign abcdefgh = ...
    // assign digit    = ...

    // Exercise 2: Display letters of a 4-character word
    // using this code to display letter of FPGA as an example

    /*
    seven_seg_encoding_e letter;

    always_comb
      case (key)
      4'b1000: letter = F;
      4'b0100: letter = P;
      4'b0010: letter = G;
      4'b0001: letter = A;
      default: letter = space;
      endcase

    assign abcdefgh = letter;
    assign digit    = key;
    */

endmodule
