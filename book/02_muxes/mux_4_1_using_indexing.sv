module mux_4_1_using_indexing
(
    input  [3:0] in,
    input  [1:0] sel,
    output logic out
);
    assign out = in [sel];

endmodule
