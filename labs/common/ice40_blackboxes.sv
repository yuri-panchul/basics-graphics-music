// Required only for read_slang yosys command, should be ignored by all other
// toolchains

`ifdef YOSYS

(* blackbox *)
module SB_GB (
    input  USER_SIGNAL_TO_GLOBAL_BUFFER,
    output GLOBAL_BUFFER_OUTPUT
);
endmodule

(* blackbox *)
module SB_PLL40_PAD (
    input   PACKAGEPIN,
    output  PLLOUTCORE,
    output  PLLOUTGLOBAL,
    input   EXTFEEDBACK,
    input   [7:0] DYNAMICDELAY,
    output  LOCK,
    input   BYPASS,
    input   RESETB,
    input   LATCHINPUTVALUE,
    output  SDO,
    input   SDI,
    input   SCLK
);
    parameter FEEDBACK_PATH = "SIMPLE";
    parameter DELAY_ADJUSTMENT_MODE_FEEDBACK = "FIXED";
    parameter DELAY_ADJUSTMENT_MODE_RELATIVE = "FIXED";
    parameter SHIFTREG_DIV_MODE = 1'b0;
    parameter FDA_FEEDBACK = 4'b0000;
    parameter FDA_RELATIVE = 4'b0000;
    parameter PLLOUT_SELECT = "GENCLK";
    parameter DIVR = 4'b0000;
    parameter DIVF = 7'b0000000;
    parameter DIVQ = 3'b000;
    parameter FILTER_RANGE = 3'b000;
    parameter ENABLE_ICEGATE = 1'b0;
    parameter TEST_MODE = 1'b0;
    parameter EXTERNAL_DIVIDE_FACTOR = 1;
endmodule

(* blackbox *)
module SB_IO (
    inout  PACKAGE_PIN,
    input  LATCH_INPUT_VALUE,
    input  CLOCK_ENABLE,
    input  INPUT_CLK,
    input  OUTPUT_CLK,
    input  OUTPUT_ENABLE,
    input  D_OUT_0,
    input  D_OUT_1,
    output D_IN_0,
    output D_IN_1
);
    parameter [5:0] PIN_TYPE = 6'b000000;
    parameter [0:0] PULLUP = 1'b0;
    parameter [0:0] NEG_TRIGGER = 1'b0;
    parameter IO_STANDARD = "SB_LVCMOS";
endmodule

`endif
