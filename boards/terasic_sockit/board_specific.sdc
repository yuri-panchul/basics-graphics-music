create_clock -period "50.0 MHz" [get_ports OSC_50_B3B]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]

set_false_path -from * -to [get_ports {LED[*]}]
set_false_path -from * -to [get_ports {VGA_*}]
