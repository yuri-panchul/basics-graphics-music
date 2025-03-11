# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.soc.cpu.pc
lappend all_signals tb.imAddr
lappend all_signals tb.imData
lappend all_signals tb.regAddr
lappend all_signals tb.regData
lappend all_signals tb.soc.cycleCnt_o

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full

# switch performance counter data format to "Decimal"
gtkwave::/Edit/Highlight_Regexp "cycleCnt_o"
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All
