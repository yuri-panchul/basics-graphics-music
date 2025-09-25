module mux_2_1_using_gates
(
    input  a,
    input  b,
    input  sel,
    output out
);
    assign out = (a & sel) | (b & ~ sel);

endmodule
