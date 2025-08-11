module full_adder
(
    input  a,
    input  b,
    input  carry_in,
    output sum,
    output carry_out
);

    assign { carry_out, sum } = a + b + carry_in;

endmodule
