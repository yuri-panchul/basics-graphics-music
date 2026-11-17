`timescale 1ns/1ps
// Test-only functional clock source. This does not model MMCM analog behavior.
// Production always instantiates the real primitives; Vivado uses UNISIM.
module MMCME2_BASE
# (
    parameter real CLKIN1_PERIOD = 83.333,
    parameter DIVCLK_DIVIDE = 1,
    parameter real CLKFBOUT_MULT_F = 50.0,
    parameter real CLKOUT0_DIVIDE_F = 6.0,
    parameter STARTUP_WAIT = "FALSE"
)
(
    input CLKIN1, CLKFBIN, RST, PWRDWN,
    output CLKFBOUT,
    output reg CLKOUT0 = 0,
    output reg LOCKED = 0
);
    integer edges = 0;
    initial
        if (DIVCLK_DIVIDE != 1 || CLKFBOUT_MULT_F != 50.0 || CLKOUT0_DIVIDE_F != 6.0)
            $fatal (1, "Unexpected Cmod clock configuration");
    always #5 CLKOUT0 = (RST || PWRDWN) ? 1'b0 : ~CLKOUT0;
    assign CLKFBOUT = CLKOUT0;
    always @ (posedge CLKIN1 or posedge RST)
        if (RST)
        begin
            edges <= 0;
            LOCKED <= 0;
        end
        else if (edges == 8)
            LOCKED <= 1;
        else
            edges <= edges + 1;
endmodule

module BUFG (input I, output O);
    assign O = I;
endmodule
