module mux_5_1_using_case
(
    input        a, b, c, d, e,
    input  [2:0] sel,
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
