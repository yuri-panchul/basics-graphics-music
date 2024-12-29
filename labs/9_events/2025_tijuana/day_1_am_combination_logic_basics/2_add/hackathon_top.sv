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

    // Adding two 4-bit numbers results in 5-bit number
    //
    //      1010
    //    + 1011
    //    ------
    //     10100  5-bit number because of carry
    //
    //     led [4:0] means { led [4], led [3], led [2], led [1], led [0] }
    //     This construct is called a "bit slice".

    assign led [4:0] = key [7:4] + key [3:0];

    // Doing arithmetics using logical operations
    //
    //    0      0      1      1   key [4]
    //  + 0    + 1    + 0    + 1   key [0]
    //  ---    ---    ---    ---
    //    0      1      1     10
    //                        ||
    //                        |+-- led [6]
    //                        +--- led [7]
    //
    // https://es.wikipedia.org/wiki/Sistema_binario

    // Exercise: Check that the following code
    // is the same as:
    //
    // assign led [7:6] = key [4] + key [0];

    assign led [7] = key [4] & key [0];
    assign led [6] = key [4] ^ key [0];

endmodule
