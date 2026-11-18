# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.cpu.pc
lappend all_signals tb.imAddr
lappend all_signals tb.imData



lappend all_signals tb.ALUResult

lappend all_signals tb.we
lappend all_signals tb.wRAMData
lappend all_signals tb.dAddr

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
