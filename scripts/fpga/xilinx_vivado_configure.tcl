
if {! [info exists hw_device]} {
    error "The variable 'hw_device' is expected to be set"
}

# New version of Vivado prefers open_hw_manager, old versions need open_hw.
# 2023 version produces "WARNING: 'open_hw' is deprecated, please use 'open_hw_manager' instead."
# However 2018 version does not accept open_hw_manager at all.

if {$fpga_board == "qmtech_kintex_7"} {
    # For whatever reason the default script in else branch
    # does not work with QMTech Kintex-7 board
    # but the followin script does work.
    # It should be reviewed with Xilinx support
    # or somebody proficient with Vivado scripting.

    open_hw
    connect_hw_server
    current_hw_target
    open_hw_target
    current_hw_device
    set_property PROGRAM.FILE fpga_project.bit [current_hw_device]
    program_hw_devices                         [current_hw_device]
    close_hw_target
    close_hw

} else {

    open_hw
    connect_hw_server
    open_hw_target
    set_property PROGRAM.FILE fpga_project.bit [get_hw_devices $hw_device]
    program_hw_devices                         [get_hw_devices $hw_device]
    close_hw_target
    close_hw
}

# See https://stackoverflow.com/questions/55495977/automate-the-usage-of-vivado-gui-by-using-tcl-scripts
# See https://docs.xilinx.com/r/en-US/ug835-vivado-tcl-commands/program_hw_devices
