# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.up_vld
lappend all_signals tb.up_rdy
lappend all_signals tb.up_data
lappend all_signals tb.down_vld
lappend all_signals tb.down_rdy
lappend all_signals tb.down_data

lappend all_signals tb.comparison_moment
lappend all_signals tb.down_data_compared
lappend all_signals tb.down_data_expected

lappend all_signals tb.dut.up_vld
lappend all_signals tb.dut.up_rdy
lappend all_signals tb.dut.up_data
lappend all_signals tb.dut.vld_1
lappend all_signals tb.dut.rdy_1
lappend all_signals tb.dut.arg_1;
lappend all_signals tb.dut.mul_1_d
lappend all_signals tb.dut.mul_1_q
lappend all_signals tb.dut.vld_2
lappend all_signals tb.dut.rdy_2
lappend all_signals tb.dut.arg_2;
lappend all_signals tb.dut.mul_2_d
lappend all_signals tb.dut.mul_2_q
lappend all_signals tb.dut.vld_3
lappend all_signals tb.dut.rdy_3
lappend all_signals tb.dut.arg_3
lappend all_signals tb.dut.mul_3_d
lappend all_signals tb.dut.mul_3_q
lappend all_signals tb.dut.vld_4
lappend all_signals tb.dut.rdy_4
lappend all_signals tb.dut.arg_4
lappend all_signals tb.dut.mul_4_d
lappend all_signals tb.dut.down_vld
lappend all_signals tb.dut.down_rdy
lappend all_signals tb.dut.down_data

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
