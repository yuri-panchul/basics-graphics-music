# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_lab_top.clk
lappend all_signals tb.i_lab_top.rst
lappend all_signals tb.i_lab_top.a_valid
lappend all_signals tb.i_lab_top.a_ready
lappend all_signals tb.i_lab_top.a_data
lappend all_signals tb.i_lab_top.b_valid
lappend all_signals tb.i_lab_top.b_ready
lappend all_signals tb.i_lab_top.b_data
lappend all_signals tb.i_lab_top.i_rra_from_fifos.a_down_valid
lappend all_signals tb.i_lab_top.i_rra_from_fifos.a_down_ready
lappend all_signals tb.i_lab_top.i_rra_from_fifos.a_down_data
lappend all_signals tb.i_lab_top.i_rra_from_fifos.b_down_valid
lappend all_signals tb.i_lab_top.i_rra_from_fifos.b_down_ready
lappend all_signals tb.i_lab_top.i_rra_from_fifos.b_down_data
lappend all_signals tb.i_lab_top.out_valid
lappend all_signals tb.i_lab_top.out_ready
lappend all_signals tb.i_lab_top.out_data

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
