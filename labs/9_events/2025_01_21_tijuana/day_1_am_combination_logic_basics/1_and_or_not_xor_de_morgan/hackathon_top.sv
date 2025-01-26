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

    assign led [0] = key [0] & key [1];

    // Exercise 1: Change the code above.
    // Assign to led [0] the result of OR operation (|).

    wire a = key [2];  // Note a new construct - wire
    wire b = key [3];

    assign led [1] = a ^ b; // XOR - eXclusive OR

    // Exercise 2: Create an illustration to De Morgan's laws:
    //
    // ~ (a & b) == ~ a | ~ b
    // ~ (a | b) == ~ a & ~ b
    //
    // https://es.wikipedia.org/wiki/Leyes_de_De_Morgan

    assign led [2] = ~ (a &   b);
    assign led [3] = ~  a | ~ b;  // The same as led [2]
    assign led [4] = ~ (a |   b);
    assign led [5] = ~  a & ~ b;  // The same as led [5]

endmodule
