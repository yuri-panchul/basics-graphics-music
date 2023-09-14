
if {! [info exists hw_device]} {
    error "The variable 'hw_device' is expected to be set"
}

open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE fpga_project.bit [get_hw_devices $hw_device]
program_hw_devices                         [get_hw_devices $hw_device]
close_hw_target
close_hw_manager

# See https://stackoverflow.com/questions/55495977/automate-the-usage-of-vivado-gui-by-using-tcl-scripts
# See https://docs.xilinx.com/r/en-US/ug835-vivado-tcl-commands/program_hw_devices
