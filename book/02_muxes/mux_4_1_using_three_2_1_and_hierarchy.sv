module mux_4_1_using_three_2_1_and_hierarchy
(
    input  [3:0] in,
    input  [1:0] sel,
    output       out
);

    logic out_01, out_23;

    mux_2_1_using_conditional_operator mux_01    (.a (in [1]), .b (in [0]), .sel (sel [0]), .out (out_01));
    mux_2_1_using_conditional_operator mux_23    (.a (in [3]), .b (in [2]), .sel (sel [0]), .out (out_23));
    mux_2_1_using_conditional_operator mux_final (.a (out_23), .b (out_01), .sel (sel [1]), .out (out));

endmodule

/*
module mux_4_1_using_three_2_1_and_hierarchy
(
    input  [3:0] in,
    input  [1:0] sel,
    output       out
);

    logic out_01, out_23;

    mux_2_1_using_conditional_operator mux_01 (
        .a (in [1]),
        .b (in [0]),
        .sel (sel [0]),
        .out (out_01));

    mux_2_1_using_conditional_operator mux_23 (
        .a (in [3]),
        .b (in [2]),
        .sel (sel [0]),
        .out (out_23));

    mux_2_1_using_conditional_operator mux_final (
        .a (out_23),
        .b (out_01),
        .sel (sel [1]),
        .out (out));

endmodule
*/
