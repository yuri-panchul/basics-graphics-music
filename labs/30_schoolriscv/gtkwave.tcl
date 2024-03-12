# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_top.clk
lappend all_signals tb.i_top.rst
lappend all_signals tb.i_top.cpu.pc
lappend all_signals tb.i_top.imAddr
lappend all_signals tb.i_top.imData
lappend all_signals tb.i_top.regAddr
lappend all_signals tb.i_top.regData

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
