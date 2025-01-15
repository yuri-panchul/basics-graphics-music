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

    // Read the theory https://es.wikipedia.org/wiki/Multiplexor

    assign sel = key [2];
    assign a   = key [1];
    assign b   = key [0];

    //------------------------------------------------------------------------

    // Five different implementations

    always_comb  // Combinational always block
    begin
        if (sel == 1)     // If sel == 1
            led [0] = a;  //    Output value of "a" to led [0]
        else
            led [0] = b;  //    Output value of "b" to led [0]
    end

    //------------------------------------------------------------------------

    always_comb  // Combinational always block
    begin
        if (sel)          // Boolean value is a condition
            led [1] = a;
        else
            led [1] = b;
    end

    //------------------------------------------------------------------------
    
    assign led [2] = sel ? a : b;  // If sel == 1, choose a, otherwise b

    //------------------------------------------------------------------------

    // You can also use "case" like "switch" in "C"

    always_comb
    begin
        case (sel)
        1'b1: led [3] = a;
        1'b0: led [3] = b;
        endcase
    end

    //------------------------------------------------------------------------

    // If you have only one statement you can omit "begin/end"

    always_comb  // Combinational always block
        if (sel)          // Boolean value is a condition
            led [4] = a;
        else
            led [4] = b;

    always_comb
        case (sel)
        1'b1: led [5] = a;
        1'b0: led [5] = b;
        endcase

    //------------------------------------------------------------------------

    // The construct "{ , }" is called "concatenation"

    wire [1:0] ab = { a, b };
    assign led [6] = ab [sel];

    // If sel == 0, we choose ab [0] which is equal to b
    // If sel == 1, we choose ab [1] which is equal to a

    //------------------------------------------------------------------------

    // Exercise: Implement mux
    // without using "?" operation, "if", "case" or a bit selection.
    // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

    assign led [7] = (a & sel) | (b & ~ sel);

endmodule
