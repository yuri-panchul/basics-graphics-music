# Run in an empty output directory. This builds a bitstream without programming.
# vivado -mode batch -source /path/to/scripts/tests/build_cmod_a7_35.tcl \
#     -tclargs labs/3_music/3_11_microphone_monitor
set root [file normalize [file join [file dirname [info script]] ../..]]
set lab_name labs/2_graphics/2_1_rectangle_ellipse_parabola
if {$argc > 1} { error "Expected at most one repository-relative lab directory" }
if {$argc == 1} { set lab_name [lindex $argv 0] }
set lab [file join $root $lab_name]
if {![file exists $lab/lab_top.sv]} { error "No lab_top.sv in $lab" }
set board $root/boards/cmod_a7_35
source $board/board_specific.tcl

create_project cmod_a7_validation ./project -part $part_name -force
set_property include_dirs [list $lab $root/labs/common $root/peripherals $board] [current_fileset]
read_verilog -sv [glob $root/labs/common/*.sv]
read_verilog -sv [glob $root/peripherals/*.sv]
foreach source [glob $lab/*.sv] {
    if {[file tail $source] ne "tb.sv"} { read_verilog -sv $source }
}
read_verilog -sv [glob $board/*.sv]
read_xdc $board/board_specific.xdc
synth_design -top board_specific_top -part $part_name -verilog_define XILINX_VIVADO
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -file timing_summary.rpt
report_drc -file drc.rpt
report_clocks -file clocks.rpt
report_utilization -file utilization.rpt
write_checkpoint -force routed.dcp

# These checks cover constrained paths; the reports also list unconstrained I/O.
set setup_slack [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
set hold_slack [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]
if {$setup_slack < 0 || $hold_slack < 0} {
    error "Timing failed: setup slack $setup_slack ns, hold slack $hold_slack ns"
}
write_bitstream -force cmod_a7_35.bit
puts "CMOD_A7_VALIDATION_COMPLETE lab=$lab_name setup_ns=$setup_slack hold_ns=$hold_slack"
