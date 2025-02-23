# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_converter.q00
lappend all_signals tb.i_converter.q90
lappend all_signals tb.i_converter.i_filtered
lappend all_signals tb.i_converter.q_filtered
lappend all_signals tb.i_converter.abs_i
lappend all_signals tb.i_converter.abs_q
lappend all_signals tb.i_converter.sum_abs
lappend all_signals tb.i_converter.ema
lappend all_signals tb.i_converter.rms_out
lappend all_signals tb.i_converter.mic
lappend all_signals tb.i_converter.switch

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full

gtkwave::/Edit/UnHighlight_All
