# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.key
lappend all_signals tb.i_lab_top.cnt
lappend all_signals tb.i_lab_top.led
lappend all_signals tb.i_lab_top.abcdefgh
lappend all_signals tb.i_lab_top.digit

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
