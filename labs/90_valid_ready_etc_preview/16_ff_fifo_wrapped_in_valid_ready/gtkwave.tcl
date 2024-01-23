# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.up_valid
lappend all_signals tb.up_ready
lappend all_signals tb.up_data
lappend all_signals tb.down_valid
lappend all_signals tb.down_ready
lappend all_signals tb.down_data

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
