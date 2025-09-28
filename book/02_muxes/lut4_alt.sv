module lut4_alt
(
    input  a, b, c, d, x0, x1,
    output y
);

    wire   ba = x0 ? b  : a;
    wire   dc = x0 ? d  : c;
    assign y  = x1 ? dc : ba;

endmodule
