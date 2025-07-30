module mux_2_1_using_conditional_operator
(
    input  a,
    input  b,
    input  sel
    output out
);
    assign out = sel ? a : b;

endmodule

module mux_2_1_width_3_using_if
(
    input        [2:0] a,
    input        [2:0] b,
    input              sel
    output logic [2:0] out
);
    always_comb
        if (sel)
            out = a;
        else
            out = b;

endmodule

module mux_5_1_using_case
(
    input        a, b, c, d, e,
    input  [2:0] sel
    output logic out
);
    always_comb
        case (sel)
        3'd0:    out = a;
        3'd1:    out = b;
        3'd2:    out = c;
        3'd3:    out = d;
        3'd4:    out = e;
        default: out = 1'b0;
        endcase

endmodule

module mux_4_1_using_indexing
(
    input  [3:0] in,
    input  [1:0] sel
    output logic out
);
    assign out = in [sel];

endmodule
