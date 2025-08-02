module mux_2_1_using_conditional_operator
(
    input  a,
    input  b,
    input  sel,
    output out
);
    assign out = sel ? a : b;

endmodule
