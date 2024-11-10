# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.dut.clk
lappend all_signals tb.dut.rst
lappend all_signals tb.dut.lr
lappend all_signals tb.dut.ws
lappend all_signals tb.dut.sck
lappend all_signals tb.dut.sd
lappend all_signals tb.dut.value
lappend all_signals tb.dut.cnt
lappend all_signals tb.dut.sample_bit
lappend all_signals tb.dut.value_done
lappend all_signals tb.dut.shift

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
