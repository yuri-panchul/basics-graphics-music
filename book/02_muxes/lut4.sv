module lut4
(
    input  [3:0] c,
    input        x0, x1,
    output       y
);

    wire   c10 = x0 ? c [1] : c [0];
    wire   c32 = x0 ? c [3] : c [2];
    assign y   = x1 ? c32   : c10;

endmodule
