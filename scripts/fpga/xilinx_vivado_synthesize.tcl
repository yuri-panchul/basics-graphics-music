# The variables fpga_board and part are defined

read_verilog -sv [glob ../../common/*.sv]
read_verilog -sv [glob ../*.sv]
read_verilog -sv [glob "../../boards/$fpga_board/*.sv"]
read_xdc "../../boards/$fpga_board/board_specific.xdc"

synth_design -top board_specific_top -part $part

report_timing_summary -file post_synth_timing_summary.rpt
report_power          -file post_synth_power.rpt

opt_design
place_design
phys_opt_design

report_timing_summary -file post_place_timing_summary.rpt

route_design

report_timing_summary    -file post_route_timing_summary.rpt
report_timing            -sort_by group -max_paths 100 -path_type summary -file post_route_timing.rpt
report_clock_utilization -file clock_util.rpt
report_utilization       -file post_route_util.rpt
report_power             -file post_route_power.rpt
report_drc               -file post_imp_drc.rpt

write_verilog                -force bft_impl_netlist.v
write_xdc     -no_fixed_only -force bft_impl.xdc

write_bitstream -force fpga_project.bit
