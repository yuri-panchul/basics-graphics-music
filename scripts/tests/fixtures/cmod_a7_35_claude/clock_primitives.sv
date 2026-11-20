// Test-only models of the two Xilinx clock primitives that
// boards/cmod_a7_35_tiny_vga_640_claude/board_specific_top.sv uses, for
// Icarus Verilog. They model only what the tests check: the output
// frequency of CLKOUT0 and LOCKED going high some time after the input
// clock starts. Vivado uses the real primitives.

`timescale 1 ns / 1 ps

module MMCME2_BASE
# (
    parameter real    CLKIN1_PERIOD    = 10.0,
    parameter integer DIVCLK_DIVIDE    = 1,
    parameter real    CLKFBOUT_MULT_F  = 5.0,
    parameter real    CLKOUT0_DIVIDE_F = 1.0
)
(
    input      CLKIN1,
    input      CLKFBIN,
    output     CLKFBOUT,
    output     CLKFBOUTB,

    output reg CLKOUT0 = 1'b0,
    output     CLKOUT0B,
    output     CLKOUT1,
    output     CLKOUT1B,
    output     CLKOUT2,
    output     CLKOUT2B,
    output     CLKOUT3,
    output     CLKOUT3B,
    output     CLKOUT4,
    output     CLKOUT5,
    output     CLKOUT6,

    output reg LOCKED = 1'b0,
    input      PWRDWN,
    input      RST
);

    localparam real vco_mhz    = 1000.0 / CLKIN1_PERIOD * CLKFBOUT_MULT_F / DIVCLK_DIVIDE,
                    out_period = 1000.0 / vco_mhz * CLKOUT0_DIVIDE_F;

    // Artix-7 speed grade -1: VCO 600 to 1200 MHz, input 10 to 800 MHz

    initial
        if (vco_mhz < 600.0 || vco_mhz > 1200.0 || CLKIN1_PERIOD > 100.0)
            $fatal (1, "MMCME2_BASE model: VCO %0.3f MHz or input period %0.3f ns out of range",
                    vco_mhz, CLKIN1_PERIOD);

    always # (out_period / 2.0) CLKOUT0 = ~ CLKOUT0;

    // The real MMCM locks within about 100 us; 64 input clocks keep the
    // simulations short

    integer n_input_clocks = 0;

    always @ (posedge CLKIN1)
    begin
        n_input_clocks = n_input_clocks + 1;

        if (n_input_clocks == 64)
            LOCKED <= 1'b1;
    end

    assign CLKFBOUT  = CLKFBIN;
    assign CLKFBOUTB = ~ CLKFBIN;
    assign CLKOUT0B  = ~ CLKOUT0;

    assign { CLKOUT1, CLKOUT1B, CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B,
             CLKOUT4, CLKOUT5, CLKOUT6 } = '0;

endmodule

//----------------------------------------------------------------------------

module BUFG (input I, output O);

    assign O = I;

endmodule
