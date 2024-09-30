# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_tb.clk
lappend all_signals tb.i_tb.rst
lappend all_signals tb.i_tb.a
lappend all_signals tb.i_tb.b
lappend all_signals tb.i_tb.sa_sum
lappend all_signals tb.i_tb.salo_sum

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full


