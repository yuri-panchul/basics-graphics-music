create_clock -period "50.0 MHz" [get_ports CLK]

derive_clock_uncertainty

set_false_path -from RST_N                 -to [all_clocks]
set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from [get_ports {CKEY[*]}] -to [all_clocks]
set_false_path -from RXD                   -to [all_clocks]
set_false_path -from [get_ports {LCD*}]    -to [all_clocks]

set_false_path -from * -to [get_ports {LED[*]}]

set_false_path -from * -to [get_ports {SEG[*]}]
set_false_path -from * -to [get_ports {DIG[*]}]

set_false_path -from * -to [get_ports {VGA*}]
set_false_path -from * -to TXD
set_false_path -from * -to [get_ports {LCD*}]
