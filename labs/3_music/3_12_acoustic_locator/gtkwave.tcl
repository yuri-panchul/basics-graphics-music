# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.sound_1
lappend all_signals tb.sound_2
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[10\].delay\[38:26\]
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[10\].delay_2
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[10\].out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[10\].abs
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[10\].ema
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[0\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[1\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[2\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[3\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[4\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[5\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[6\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[7\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[8\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[9\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[10\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[11\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[12\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[13\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[14\].rms_out
lappend all_signals tb.i_lab_top.i_locator.i_correlator_h\[15\].rms_out

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::highlightSignalsFromList "tb.sound_1\[23:0\]"
gtkwave::highlightSignalsFromList "tb.sound_2\[23:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[10\].delay\[38:26\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[10\].delay_2\[12:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Signed_Decimal
gtkwave::/Edit/UnHighlight_All

gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[10\].out\[13:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Signed_Decimal
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/UnHighlight_All

gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[10\].abs\[13:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[10\].ema\[19:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[0\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[1\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[2\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[3\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[4\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[5\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[6\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[7\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[8\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[9\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[10\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[11\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[12\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[13\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[14\].rms_out\[12:0\]"
gtkwave::highlightSignalsFromList "tb.i_lab_top.i_locator.i_correlator_h\[15\].rms_out\[12:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All

gtkwave::/Time/Zoom/Zoom_Full
