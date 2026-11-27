// Seven-segment glyphs for the letters and digits shown in
// labs/1_basics/1_05_7seven_segment_letter/seven_segment_alphabet.jpg
//
// Include this file inside a module body, the same way dig_to_seg
// is declared inside seven_segment_display (labs/common), for example:
//
//     `include "seven_segment_alphabet_function.svh"
//
//     assign abcdefgh = seven_segment_alphabet ("F");
//
// Upper and lower case letters give the same glyph.
// Any other character gives a blank digit. The dot (h) is always off.
//
// Some glyphs are the same:
// 0 and O, 2 and Z, 5 and S, 9 and G, H and K and X.
//
// Unlike dig_to_seg, 9 has its bottom segment (d) lit,
// as in the picture, so it is different from q.

function [7:0] seven_segment_alphabet (input [7:0] ascii);

    case (ascii)

    "A", "a": seven_segment_alphabet = 8'b1110_1110;  // a b c d e f g h
    "B", "b": seven_segment_alphabet = 8'b0011_1110;
    "C", "c": seven_segment_alphabet = 8'b1001_1100;  //   --a--
    "D", "d": seven_segment_alphabet = 8'b0111_1010;  //  |     |
    "E", "e": seven_segment_alphabet = 8'b1001_1110;  //  f     b
    "F", "f": seven_segment_alphabet = 8'b1000_1110;  //  |     |
    "G", "g": seven_segment_alphabet = 8'b1111_0110;  //   --g--
    "H", "h": seven_segment_alphabet = 8'b0110_1110;  //  |     |
    "I", "i": seven_segment_alphabet = 8'b0000_1100;  //  e     c
    "J", "j": seven_segment_alphabet = 8'b0111_1000;  //  |     |
    "K", "k": seven_segment_alphabet = 8'b0110_1110;  //   --d--  h
    "L", "l": seven_segment_alphabet = 8'b0001_1100;
    "M", "m": seven_segment_alphabet = 8'b1010_1000;

    "N", "n": seven_segment_alphabet = 8'b0010_1010;
    "O", "o": seven_segment_alphabet = 8'b1111_1100;
    "P", "p": seven_segment_alphabet = 8'b1100_1110;
    "Q", "q": seven_segment_alphabet = 8'b1110_0110;
    "R", "r": seven_segment_alphabet = 8'b0000_1010;
    "S", "s": seven_segment_alphabet = 8'b1011_0110;
    "T", "t": seven_segment_alphabet = 8'b0001_1110;
    "U", "u": seven_segment_alphabet = 8'b0111_1100;
    "V", "v": seven_segment_alphabet = 8'b0011_1000;
    "W", "w": seven_segment_alphabet = 8'b0101_0100;
    "X", "x": seven_segment_alphabet = 8'b0110_1110;
    "Y", "y": seven_segment_alphabet = 8'b0111_0110;
    "Z", "z": seven_segment_alphabet = 8'b1101_1010;

    "0":      seven_segment_alphabet = 8'b1111_1100;
    "1":      seven_segment_alphabet = 8'b0110_0000;
    "2":      seven_segment_alphabet = 8'b1101_1010;
    "3":      seven_segment_alphabet = 8'b1111_0010;
    "4":      seven_segment_alphabet = 8'b0110_0110;
    "5":      seven_segment_alphabet = 8'b1011_0110;
    "6":      seven_segment_alphabet = 8'b1011_1110;
    "7":      seven_segment_alphabet = 8'b1110_0000;
    "8":      seven_segment_alphabet = 8'b1111_1110;
    "9":      seven_segment_alphabet = 8'b1111_0110;

    default:  seven_segment_alphabet = 8'b0000_0000;

    endcase

endfunction
