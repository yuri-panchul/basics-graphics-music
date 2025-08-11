module first_design
(
    input  a, b, c, d,
    output e, f
);

    assign e = a & (b | c);
    assign f = ~ (c ^ d);

endmodule
                