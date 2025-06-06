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
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);

    //------------------------------------------------------------------------

    // Gates, wires and continuous assignments

    assign led [0] = key [0] & key [1];

    // Exercise 1: Change the code above.
    // Assign to led [0] the result of OR operation (|).

    wire a = key [0];  // Note a new construct - wire
    wire b = key [1];

    assign led [1] = a ^ b; // XOR - eXclusive OR

    //------------------------------------------------------------------------

    // Signals for demoing multiplexers

    assign sel = key [7];
    assign d1  = key [6];
    assign d0  = key [5];

    //------------------------------------------------------------------------

    // Five different implementations

    always_comb  // Combinational always block
    begin
        if (sel == 1)     // If sel == 1
            led [7] = d1;  //    Output value of "a" to led [0]
        else
            led [7] = d0;  //    Output value of "b" to led [0]
    end

    //------------------------------------------------------------------------

    /*

    // "== 1" is not necessary
    // because Boolean value can be used as an "if" condition

    always_comb  // Combinational always block
    begin
        if (sel)
            led [7] = d1;
        else
            led [7] = d0;
    end

    */

    //------------------------------------------------------------------------

    assign led [6] = sel ? d1 : d0;  // If sel == 1, choose d1, otherwise d0

    //------------------------------------------------------------------------

    // You can also use "case" like "switch" in "C"

    always_comb
    begin
        case (sel)
        1: led [5] = d1;
        0: led [5] = d0;
        endcase
    end

    //------------------------------------------------------------------------

    /*

    // If you have only one statement you can omit "begin/end"

    always_comb
        if (sel)
            led [7] = d1;
        else
            led [7] = d0;

    always_comb
        case (sel)
        1: led [5] = d1;
        0: led [5] = d0;
        endcase

    */

    //------------------------------------------------------------------------

    // The construct "{ , }" is called "concatenation"

    wire [1:0] d = { d1, d0 };
    assign led [4] = d [sel];

    // If sel == 0, we choose d [0] which is equal to d0
    // If sel == 1, we choose d [1] which is equal to d1

    //------------------------------------------------------------------------

    // Exercise: Implement mux
    // without using "?" operation, "if", "case" or a bit selection.
    // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

    //------------------------------------------------------------------------

    // Exercise: Implement a mux that chooses between four inputs
    // using two-bit selector.

endmodule
