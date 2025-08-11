// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
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
/*
    localparam P = 8'b1100_1110;
    localparam A = 8'b1110_1110;
*/
    localparam P = 8'b1100_1110,
               A = 8'b1110_1110,
               N = 8'b0010_1010,
               C = 8'b1001_1100,
               H = 8'b0110_1110,
               U = 8'b0111_1100,
               L = 8'b0001_1100,
               nothing = 8'b0;

    //assign digit = key;

    always_comb
    begin
/*
        case (key)
        8'b1000_0000: abcdefgh = P;
        8'b0100_0000: abcdefgh = A;
        8'b0010_0000: abcdefgh = N;
        8'b0001_0000: abcdefgh = C;
        8'b0000_1000: abcdefgh = H;
        8'b0000_0100: abcdefgh = U;
        8'b0000_0010: abcdefgh = L;
        default:      abcdefgh = nothing;
        endcase
*/
/*
             if (key [7]) abcdefgh = P;
        else if (key [6]) abcdefgh = A;
        else if (key [5]) abcdefgh = N;
        else if (key [4]) abcdefgh = C;
        else if (key [3]) abcdefgh = H;
        else if (key [2]) abcdefgh = U;
        else if (key [1]) abcdefgh = L;
        else              abcdefgh = nothing;
*/
        casez (key)
        8'b1???_????: abcdefgh = P;
        8'b01??_????: abcdefgh = A;
        8'b001?_????: abcdefgh = N;
        8'b0001_????: abcdefgh = C;
        8'b0000_1???: abcdefgh = H;
        8'b0000_01??: abcdefgh = U;
        8'b0000_001?: abcdefgh = L;
        default:      abcdefgh = nothing;
        endcase


             if (key [7]) digit = 8'b10000000;
        else if (key [6]) digit = 8'b01000000;
        else if (key [5]) digit = 8'b00100000;
        else if (key [4]) digit = 8'b00010000;
        else if (key [3]) digit = 8'b00001000;
        else if (key [2]) digit = 8'b00000100;
        else if (key [1]) digit = 8'b00000010;
        else              digit = 8'b00000000;
    end

    // assign abcdefgh = ~ key [0] ? P : A;

/*
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
*/
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
