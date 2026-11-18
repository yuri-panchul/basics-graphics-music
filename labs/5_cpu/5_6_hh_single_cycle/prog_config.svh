`ifndef PROG_CONFIG_SVH
`define PROG_CONFIG_SVH

`define USE_RISCVTEST_HEX

`ifdef USE_RISCVTEST_HEX
    `define PROGRAM_FILE_NAME "riscvtest.hex"
`else
    `define PROGRAM_FILE_NAME "program.hex"
`endif

`define INSTRUCTION_ROM_DEPTH 64

`endif  // `ifndef PROG_CONFIG_SVH
