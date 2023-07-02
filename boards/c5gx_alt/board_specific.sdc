create_clock -period "50.0 MHz" [get_ports clock_50_b8a]

derive_clock_uncertainty

set_false_path -from [get_ports {key[*]}]  -to [all_clocks]
set_false_path -from [get_ports {sw[*]}]   -to [all_clocks]
set_false_path -from uart_rx               -to [all_clocks]
set_false_path -from [get_ports {gpio[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {ledr[*]}]
set_false_path -from * -to [get_ports {ledg[*]}]

set_false_path -from * -to [get_ports {hex0[*]}]
set_false_path -from * -to [get_ports {hex1[*]}]
set_false_path -from * -to [get_ports {hex2[*]}]
set_false_path -from * -to [get_ports {hex3[*]}]

set_false_path -from * -to [get_ports {gpio[*]}]
