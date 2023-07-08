`ifndef CONFIG_SVH
`define CONFIG_SVH

`timescale 1 ns / 1 ps

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
    // Verilator https://www.veripool.org/wiki/verilator
`elsif XILINX_ISIM
    // Xilinx ISE Simulator
`elsif XILINX_SIMULATOR
    // Xilinx Vivado Simulator
`elsif Veritak
    // Veritak http://www.sugawara-systems.com
`else
    `define NO_SIMULATION
`endif

`ifdef NO_SIMULATION
    `define SYNTHESIS
`else
    `define SIMULATION
`endif

`endif  // ifndef CONFIG_SVH
