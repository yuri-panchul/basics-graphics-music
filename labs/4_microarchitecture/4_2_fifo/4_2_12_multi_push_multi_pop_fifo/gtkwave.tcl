# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.res_exp
lappend all_signals tb.res
lappend all_signals tb.n_push
lappend all_signals tb.push_data
lappend all_signals tb.n_pop
lappend all_signals tb.pop_data


set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
