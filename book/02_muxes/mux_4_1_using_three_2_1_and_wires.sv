module mux_4_1_using_three_2_1_and_wires
(
    input  [3:0] in,
    input  [1:0] sel,
    output       out
);

    wire   out_01 = sel [0] ? in [1] : in [0];
    wire   out_23 = sel [0] ? in [3] : in [2];
    assign out    = sel [1] ? out_23 : out_01;

endmodule
