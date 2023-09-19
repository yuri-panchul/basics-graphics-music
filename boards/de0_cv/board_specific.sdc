create_clock -period "50.0 MHz" [get_ports CLOCK_50]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from RESET_N               -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {GPIO_*}]  -to [all_clocks]

set_false_path -from * -to [get_ports {LEDR[*]}]

set_false_path -from * -to [get_ports {HEX*}]

set_false_path -from * -to [get_ports {VGA*}]

set_false_path -from * -to [get_ports {GPIO_*}]
