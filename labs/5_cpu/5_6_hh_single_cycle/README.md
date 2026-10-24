# TODO

asic_config.tcl - keep as is unless need to increase size
asic_top.sv - keep as is
companion - don't modify
gtkwave.tcl - add signals for riscvsingle.sv
instruction_rom.sv - change comment, possibly the default size
lab_top.sv - main work, add data memory and glue logic
program.s - we should be able to run the original program.s as well as riscvtest.s
README.md - this file, document the example later on
riscvsingle.sv - add `ifdef ORIGINAL_TB around testbench
riscvtest.s - we are going to copy this later into program.s
surfer.scr - add signals for riscvsingle.sv
tb.sv - main work, modify the testbench

Main work: rewrite lab_top.sv and tb.sv
