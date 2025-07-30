module mux_2_1_width_3_using_if
(
    input        [2:0] a,
    input        [2:0] b,
    input              sel,
    output logic [2:0] out
);
    always_comb
        if (sel)
            out = a;
        else
            out = b;

endmodule
