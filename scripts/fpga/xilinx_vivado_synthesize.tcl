
if {! [info exists fpga_board]} {
    error "The variable 'fpga_board' is expected to be set"
}

if {! [info exists part_name]} {
    error "The variable 'part_name' is expected to be set"
}

set extra_dot_dot ""
create_project  board_specific_top ./gui_prj           \
               -part $part_name                        \
               -force                                  \
               -quiet

if {[file isdirectory ../../../../../labs]} {
    set extra_dot_dot ../
}

read_verilog -sv [glob $extra_dot_dot../../../common/*.sv]

foreach file [glob ../*.{v,sv}] {
    if {$file ne "../tb.sv"} {
        read_verilog -sv $file
    }
}

read_verilog -sv [glob $extra_dot_dot../../../../peripherals/*.sv]

read_verilog -sv [glob $extra_dot_dot../../../../boards/$fpga_board/*.sv]

read_xdc $extra_dot_dot../../../../boards/$fpga_board/board_specific.xdc

synth_design -verilog_define XILINX_VIVADO                \
             -include_dirs $extra_dot_dot../../../common  \
             -include_dirs $extra_dot_dot../../../../peripherals  \
             -part $part_name                             \
             -top board_specific_top

write_checkpoint          -force post_synth
report_timing_summary     -file  post_synth_timing_summary.rpt
report_power              -file  post_synth_power.rpt

opt_design
power_opt_design
place_design
phys_opt_design

write_checkpoint          -force post_place
report_timing_summary     -file  post_place_timing_summary.rpt

route_design

write_checkpoint          -force post_route
report_timing_summary     -file  post_route_timing_summary.rpt
report_timing             -sort_by group -max_paths 100 -path_type summary -file post_route_timing.rpt
report_clock_utilization  -file  clock_util.rpt
report_utilization        -file  post_route_util.rpt
report_power              -file  post_route_power.rpt
report_drc                -file  post_imp_drc.rpt

write_verilog             -force bft_impl_netlist.v
write_xdc -no_fixed_only  -force bft_impl.xdc

write_bitstream           -force fpga_project.bit
