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
        R     = 8'b1100_1100,  // This means "8-bit binary number"
        P     = 8'b1100_1110,
        E     = 8'b1001_1110,
        A     = 8'b1110_1110,
        F     = 8'b1000_1110,  // This means "8-bit binary number"
        G     = 8'b1011_1110,
        B     = 8'b0011_1110,
        S     = 8'b1011_0111,
        T     = 8'b0011_1100,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

    assign abcdefgh = key [0] ? P : R;
    assign digit    = key [1] ? 2'b10 : 2'b01;

    // Exercise 1: Display the first letters
    // of your first name and last name instead.

    // assign abcdefgh = ...
    // assign digit    = ...
    
    /*
    assign abcdefgh = key[3] ? P : (key[2] ? E : (key[1] ? R : (key[0] ? A : space)));
    assign digit = (key[3]) ? 4'b1000 :   // se enciende 5
               (key[2]) ? 4'b0100 :   // se enciende 6
               (key[1]) ? 4'b0010 :   // se enciende 7
               (key[0]) ? 4'b0001 :   // se enciende 8
               4'b0000;               //apagar
    */


    // Exercise 2: Display letters of a 4-character word
    // using this code to display letter of FPGA as an example

/*    
    seven_seg_encoding_e letter;

    always_comb
      case (key)
      4'b1000: letter = B;
      4'b0100: letter = A;
      4'b0010: letter = S;
      4'b0001: letter = T;
      default: letter = space;
      endcase

    assign abcdefgh = letter;
    assign digit    = key;
*/

endmodule
