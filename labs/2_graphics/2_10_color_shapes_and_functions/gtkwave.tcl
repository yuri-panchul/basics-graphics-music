# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_display.pixel_29
lappend all_signals tb.i_display.pixel_28
lappend all_signals tb.i_display.pixel_27
lappend all_signals tb.i_display.pixel_26
lappend all_signals tb.i_display.pixel_25
lappend all_signals tb.i_display.pixel_24
lappend all_signals tb.i_display.pixel_23
lappend all_signals tb.i_display.pixel_22
lappend all_signals tb.i_display.pixel_21
lappend all_signals tb.i_display.pixel_20
lappend all_signals tb.i_display.pixel_19
lappend all_signals tb.i_display.pixel_18
lappend all_signals tb.i_display.pixel_17
lappend all_signals tb.i_display.pixel_16
lappend all_signals tb.i_display.pixel_15
lappend all_signals tb.i_display.pixel_14
lappend all_signals tb.i_display.pixel_13
lappend all_signals tb.i_display.pixel_12
lappend all_signals tb.i_display.pixel_11
lappend all_signals tb.i_display.pixel_10
lappend all_signals tb.i_display.pixel_09
lappend all_signals tb.i_display.pixel_08
lappend all_signals tb.i_display.pixel_07
lappend all_signals tb.i_display.pixel_06
lappend all_signals tb.i_display.pixel_05
lappend all_signals tb.i_display.pixel_04
lappend all_signals tb.i_display.pixel_03
lappend all_signals tb.i_display.pixel_02
lappend all_signals tb.i_display.pixel_01
lappend all_signals tb.i_display.pixel_00

lappend all_signals tb.i_lcd.LCD_DE
lappend all_signals tb.LCD_R
lappend all_signals tb.LCD_G
lappend all_signals tb.LCD_B
lappend all_signals tb.x
lappend all_signals tb.y

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::highlightSignalsFromList "tb.LCD_R\[4:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Decimal

gtkwave::highlightSignalsFromList "tb.LCD_G\[5:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Decimal

gtkwave::highlightSignalsFromList "tb.LCD_B\[4:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Decimal

gtkwave::highlightSignalsFromList "tb.x\[8:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Decimal

gtkwave::highlightSignalsFromList "tb.y\[8:0\]"
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Decimal

gtkwave::/Time/Zoom/Zoom_Full
gtkwave::/Time/Zoom/Zoom_In
gtkwave::/Time/Zoom/Zoom_In
gtkwave::/Time/Zoom/Zoom_In
gtkwave::/Time/Zoom/Zoom_In
gtkwave::/Time/Zoom/Zoom_In
gtkwave::/Time/Zoom/Zoom_To_End

gtkwave::/Edit/UnHighlight_All
