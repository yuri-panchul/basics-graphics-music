# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.start
lappend all_signals tb.angle
lappend all_signals tb.calc
lappend all_signals tb.finish
lappend all_signals tb.cos_out
lappend all_signals tb.sin_out

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
