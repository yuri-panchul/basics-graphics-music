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
    assign a   = key [6];
    assign b   = key [5];

    //------------------------------------------------------------------------

    // Five different implementations

    always_comb  // Combinational always block
    begin
        if (sel == 1)     // If sel == 1
            led [7] = a;  //    Output value of "a" to led [0]
        else
            led [7] = b;  //    Output value of "b" to led [0]
    end

    //------------------------------------------------------------------------

    /*
    
    // "== 1" is not necessary
    // because Boolean value can be used as an "if" condition

    always_comb  // Combinational always block
    begin
        if (sel)
            led [7] = a;
        else
            led [7] = b;
    end
    
    */

    //------------------------------------------------------------------------

    assign led [6] = sel ? a : b;  // If sel == 1, choose a, otherwise b

    //------------------------------------------------------------------------

    // You can also use "case" like "switch" in "C"

    always_comb
    begin
        case (sel)
        1: led [5] = a;
        0: led [5] = b;
        endcase
    end

    //------------------------------------------------------------------------

    /*
    
    // If you have only one statement you can omit "begin/end"

    always_comb
        if (sel)
            led [7] = a;
        else
            led [7] = b;

    always_comb
        case (sel)
        1: led [5] = a;
        0: led [5] = b;
        endcase
        
    */

    //------------------------------------------------------------------------

    // The construct "{ , }" is called "concatenation"

    wire [1:0] ab = { a, b };
    assign led [4] = ab [sel];

    // If sel == 0, we choose ab [0] which is equal to b
    // If sel == 1, we choose ab [1] which is equal to a

    //------------------------------------------------------------------------

    // Exercise: Implement mux
    // without using "?" operation, "if", "case" or a bit selection.
    // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

    // START_SOLUTION

    assign led [3] = (a & sel) | (b & ~ sel);

    // END_SOLUTION

endmodule
