// Seven-segment glyphs for the printable ASCII characters 0x20-0x5F
// (space to underscore) shown in
// labs/1_basics/1_05_7seven_segment_letter/seven_segment_font_editor.jpg
//
// Include this file inside a module body, the same way dig_to_seg
// is declared inside seven_segment_display (labs/common), for example:
//
//     `include "seven_segment_font_function.svh"
//
//     assign abcdefgh = seven_segment_font ("F");
//
// Lower case letters give the same glyph as upper case letters.
// Characters the picture does not show (control codes, `, {, |, }, ~
// and codes above 0x7E) give a blank digit.
//
// The dot (h) is lit only for "!" and ".".
//
// Unlike dig_to_seg, 9 has its bottom segment (d) lit, as in the picture.

function [7:0] seven_segment_font (input [7:0] ascii);

    case (ascii)

    " ":      seven_segment_font = 8'b0000_0000;  // a b c d e f g h
    "!":      seven_segment_font = 8'b0100_0001;
    "\"":     seven_segment_font = 8'b0100_0100;  //   --a--
    "#":      seven_segment_font = 8'b0110_1100;  //  |     |
    "$":      seven_segment_font = 8'b1001_0110;  //  f     b
    "%":      seven_segment_font = 8'b1011_0100;  //  |     |
    "&":      seven_segment_font = 8'b1101_1110;  //   --g--
    "'":      seven_segment_font = 8'b0000_0100;  //  |     |
    "(":      seven_segment_font = 8'b1001_1100;  //  e     c
    ")":      seven_segment_font = 8'b1111_0000;  //  |     |
    "*":      seven_segment_font = 8'b1100_0110;  //   --d--  h
    "+":      seven_segment_font = 8'b0000_1110;
    ",":      seven_segment_font = 8'b0011_0000;
    "-":      seven_segment_font = 8'b0000_0010;
    ".":      seven_segment_font = 8'b0000_0001;
    "/":      seven_segment_font = 8'b0100_0010;

    "0":      seven_segment_font = 8'b1111_1100;
    "1":      seven_segment_font = 8'b0110_0000;
    "2":      seven_segment_font = 8'b1101_1010;
    "3":      seven_segment_font = 8'b1111_0010;
    "4":      seven_segment_font = 8'b0110_0110;
    "5":      seven_segment_font = 8'b1011_0110;
    "6":      seven_segment_font = 8'b1011_1110;
    "7":      seven_segment_font = 8'b1110_0000;
    "8":      seven_segment_font = 8'b1111_1110;
    "9":      seven_segment_font = 8'b1111_0110;
    ":":      seven_segment_font = 8'b0001_0010;
    ";":      seven_segment_font = 8'b0011_0010;
    "<":      seven_segment_font = 8'b1000_0110;
    "=":      seven_segment_font = 8'b1000_0010;
    ">":      seven_segment_font = 8'b1100_0010;
    "?":      seven_segment_font = 8'b1100_1010;

    "@":      seven_segment_font = 8'b1111_1010;
    "A", "a": seven_segment_font = 8'b1110_1110;
    "B", "b": seven_segment_font = 8'b0011_1110;
    "C", "c": seven_segment_font = 8'b1001_1100;
    "D", "d": seven_segment_font = 8'b0111_1010;
    "E", "e": seven_segment_font = 8'b1001_1110;
    "F", "f": seven_segment_font = 8'b1000_1110;
    "G", "g": seven_segment_font = 8'b1011_1100;
    "H", "h": seven_segment_font = 8'b0010_1110;
    "I", "i": seven_segment_font = 8'b0000_1100;
    "J", "j": seven_segment_font = 8'b0111_1000;
    "K", "k": seven_segment_font = 8'b1010_1110;
    "L", "l": seven_segment_font = 8'b0001_1100;
    "M", "m": seven_segment_font = 8'b1010_1000;
    "N", "n": seven_segment_font = 8'b1110_1100;
    "O", "o": seven_segment_font = 8'b1111_1100;

    "P", "p": seven_segment_font = 8'b1100_1110;
    "Q", "q": seven_segment_font = 8'b1110_0110;
    "R", "r": seven_segment_font = 8'b1100_1100;
    "S", "s": seven_segment_font = 8'b1011_0110;
    "T", "t": seven_segment_font = 8'b0001_1110;
    "U", "u": seven_segment_font = 8'b0111_1100;
    "V", "v": seven_segment_font = 8'b0111_0100;
    "W", "w": seven_segment_font = 8'b0101_0100;
    "X", "x": seven_segment_font = 8'b0110_1110;
    "Y", "y": seven_segment_font = 8'b0111_0110;
    "Z", "z": seven_segment_font = 8'b1101_0010;
    "[":      seven_segment_font = 8'b1001_1100;
    "\\":     seven_segment_font = 8'b0000_0110;
    "]":      seven_segment_font = 8'b1111_0000;
    "^":      seven_segment_font = 8'b1100_0100;
    "_":      seven_segment_font = 8'b0001_0000;

    default:  seven_segment_font = 8'b0000_0000;

    endcase

endfunction
