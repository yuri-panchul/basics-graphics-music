# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals tb.clk
lappend all_signals tb.rst
lappend all_signals tb.key
lappend all_signals tb.key_0
lappend all_signals tb.key_1
lappend all_signals tb.i_lab_top.cnt
lappend all_signals tb.i_lab_top.led
lappend all_signals tb.i_lab_top.abcdefgh
lappend all_signals tb.i_lab_top.digit
lappend all_signals tb.i_lab_top.last_bytes
lappend all_signals tb.i_lab_top.last_address
lappend all_signals tb.i_lab_top.last_word
lappend all_signals tb.i_lab_top.word_data
lappend all_signals tb.i_lab_top.word_address
lappend all_signals tb.i_lab_top.byte_valid
lappend all_signals tb.i_lab_top.number
lappend all_signals tb.uart_rx
lappend all_signals tb.i_lab_top.receiver.load_counter
lappend all_signals tb.i_lab_top.receiver.counter_done
lappend all_signals tb.uart_tx

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
