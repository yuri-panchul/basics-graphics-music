# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_led_strip_combo.clk
lappend all_signals tb.i_led_strip_combo.clk_div
lappend all_signals tb.i_led_strip_combo.cnt_3
lappend all_signals tb.i_led_strip_combo.cnt_ws2812
lappend all_signals tb.i_led_strip_combo.data_rgb
lappend all_signals tb.i_led_strip_combo.data_rgb_reg
lappend all_signals tb.i_led_strip_combo.sk9822_clk
lappend all_signals tb.i_led_strip_combo.sk9822_data
lappend all_signals tb.i_led_strip_combo.ws2812

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full

gtkwave::highlightSignalsFromList "tb.i_led_strip_combo.clk_div\[14:0\]"
gtkwave::/Edit/Data_Format/Decimal

gtkwave::highlightSignalsFromList "tb.i_led_strip_combo.cnt_3\[1:0\]"
gtkwave::/Edit/Data_Format/Decimal

gtkwave::highlightSignalsFromList "tb.i_led_strip_combo.cnt_ws2812\[4:0\]"
gtkwave::/Edit/Data_Format/Decimal

gtkwave::/Edit/UnHighlight_All
