`ifndef CONFIG_SVH
`define CONFIG_SVH

`timescale 1 ns / 1 ps

`ifdef ALTERA_RESERVED_QIS
    `default_nettype none
`endif

//----------------------------------------------------------------------------

`ifdef VCS
    // Synopsys VCS
`elsif INCA
    // Cadence NC-Verilog, IUS and Xcelium
`elsif MODEL_TECH
    // Mentor Graphics / Siemens EDA - ModelSim / Questa
`elsif __ICARUS__
    // Icarus Verilog http://iverilog.icarus.com
`elsif VERILATOR
    // Underscore below is needed so that Verilator
    // does not recognize this comment as a directive.
    // _ Verilator https://www.veripool.org/wiki/verilator
`elsif XILINX_ISIM
    // Xilinx ISE Simulator
`elsif XILINX_SIMULATOR
    // Xilinx Vivado Simulator
`elsif Veritak
    // Veritak http://www.sugawara-systems.com
`elsif _VCP
    // Aldec
`else
    `define NO_SIMULATION
`endif

`ifdef NO_SIMULATION
    `define SYNTHESIS
`else
    `define SIMULATION
`endif

// This define is useful for using some SV features,
// like complex array initialization, not supported by Icarus

`ifdef VCS
    `define SYNOPSYS_CADENCE_MENTOR
`elsif INCA
    `define SYNOPSYS_CADENCE_MENTOR
`elsif MODEL_TECH
    `define SYNOPSYS_CADENCE_MENTOR
`endif

`endif  // ifndef CONFIG_SVH
