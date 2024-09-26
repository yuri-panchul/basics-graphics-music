# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.a_valid
lappend all_signals tb.a_ready
lappend all_signals tb.a_data
lappend all_signals tb.b_valid
lappend all_signals tb.b_ready
lappend all_signals tb.b_data
lappend all_signals tb.sum_valid
lappend all_signals tb.sum_ready
lappend all_signals tb.sum_data

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
