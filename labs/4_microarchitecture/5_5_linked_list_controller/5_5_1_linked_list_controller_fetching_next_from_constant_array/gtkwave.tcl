# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.key
lappend all_signals tb.i_lab_top.led
lappend all_signals tb.i_lab_top.abcdefgh

lappend all_signals tb.i_lab_top.start_pointer
lappend all_signals tb.i_lab_top.start_pointer_valid
lappend all_signals tb.i_lab_top.start_pointer_ready

lappend all_signals tb.i_lab_top.out_data_valid
lappend all_signals tb.i_lab_top.out_data

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Edit/UnHighlight_All
gtkwave::highlightSignalsFromList "tb.i_lab_top.led\[7:0\]"
gtkwave::/Edit/Data_Format/ASCII
gtkwave::/Edit/UnHighlight_All

gtkwave::/Time/Zoom/Zoom_Full
