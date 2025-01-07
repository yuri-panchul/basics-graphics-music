# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.key
lappend all_signals tb.sound

lappend all_signals tb.i_i2s_audio_out.clk_mhz
lappend all_signals tb.i_i2s_audio_out.in_res
lappend all_signals tb.i_i2s_audio_out.align_right
lappend all_signals tb.i_i2s_audio_out.offset_by_one_cycle
lappend all_signals tb.i_i2s_audio_out.shift
lappend all_signals tb.i_i2s_audio_out.data_aligned

lappend all_signals tb.mclk
lappend all_signals tb.bclk
lappend all_signals tb.lrclk
lappend all_signals tb.sdata

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full

gtkwave::highlightSignalsFromList "tb.sound\[15:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Signed_Decimal
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/UnHighlight_All

gtkwave::highlightSignalsFromList "tb.i_i2s_audio_out.data_aligned\[31:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Signed_Decimal
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/Insert_Analog_Height_Extension
gtkwave::/Edit/UnHighlight_All
