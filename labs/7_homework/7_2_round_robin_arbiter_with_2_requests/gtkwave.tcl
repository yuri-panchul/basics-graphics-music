# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_tb.clk
lappend all_signals tb.i_tb.rst
lappend all_signals tb.i_tb.requests
lappend all_signals tb.i_tb.grants
lappend all_signals tb.i_tb.arbiter.last_grant_0

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
