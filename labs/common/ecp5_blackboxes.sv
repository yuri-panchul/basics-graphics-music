// Required only for read_slang yosys command, should be ignored by all other
// toolchains

`ifdef YOSYS

(* blackbox *)
module DCCA(CLKI, CE, CLKO);
    input CLKI;
    input CE;
    output CLKO;
endmodule

(* blackbox *)
module EHXPLLL(CLKI, CLKFB, PHASESEL1, PHASESEL0, PHASEDIR, PHASESTEP, PHASELOADREG, STDBY, PLLWAKESYNC, RST, ENCLKOP, ENCLKOS, ENCLKOS2, ENCLKOS3, CLKOP, CLKOS, CLKOS2, CLKOS3, LOCK, INTLOCK, REFCLK
, CLKINTFB);
    parameter CLKI_DIV = 1;
    parameter CLKFB_DIV = 1;
    parameter CLKOP_DIV = 8;
    parameter CLKOS_DIV = 8;
    parameter CLKOS2_DIV = 8;
    parameter CLKOS3_DIV = 8;
    parameter CLKOP_ENABLE = "ENABLED";
    parameter CLKOS_ENABLE = "DISABLED";
    parameter CLKOS2_ENABLE = "DISABLED";
    parameter CLKOS3_ENABLE = "DISABLED";
    parameter CLKOP_CPHASE = 0;
    parameter CLKOS_CPHASE = 0;
    parameter CLKOS2_CPHASE = 0;
    parameter CLKOS3_CPHASE = 0;
    parameter CLKOP_FPHASE = 0;
    parameter CLKOS_FPHASE = 0;
    parameter CLKOS2_FPHASE = 0;
    parameter CLKOS3_FPHASE = 0;
    parameter FEEDBK_PATH = "CLKOP";
    parameter CLKOP_TRIM_POL = "RISING";
    parameter CLKOP_TRIM_DELAY = 0;
    parameter CLKOS_TRIM_POL = "RISING";
    parameter CLKOS_TRIM_DELAY = 0;
    parameter OUTDIVIDER_MUXA = "DIVA";
    parameter OUTDIVIDER_MUXB = "DIVB";
    parameter OUTDIVIDER_MUXC = "DIVC";
    parameter OUTDIVIDER_MUXD = "DIVD";
    parameter PLL_LOCK_MODE = 0;
    parameter PLL_LOCK_DELAY = 200;
    parameter STDBY_ENABLE = "DISABLED";
    parameter REFIN_RESET = "DISABLED";
    parameter SYNC_ENABLE = "DISABLED";
    parameter INT_LOCK_STICKY = "ENABLED";
    parameter DPHASE_SOURCE = "DISABLED";
    parameter PLLRST_ENA = "DISABLED";
    parameter INTFB_WAKE = "DISABLED";
    input CLKI;
    input CLKFB;
    input PHASESEL1;
    input PHASESEL0;
    input PHASEDIR;
    input PHASESTEP;
    input PHASELOADREG;
    input STDBY;
    input PLLWAKESYNC;
    input RST;
    input ENCLKOP;
    input ENCLKOS;
    input ENCLKOS2;
    input ENCLKOS3;
    output CLKOP;
    output CLKOS;
    output CLKOS2;
    output CLKOS3;
    output LOCK;
    output INTLOCK;
    output REFCLK;
    output CLKINTFB;
endmodule

`endif
