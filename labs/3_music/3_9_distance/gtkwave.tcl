# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.i_sensor.echo
lappend all_signals tb.i_sensor.relative_distance

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full

gtkwave::highlightSignalsFromList "tb.i_sensor.relative_distance\[7:0\]"
gtkwave::/Edit/Data_Format/Decimal
