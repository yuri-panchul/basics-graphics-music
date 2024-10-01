create_clock -period "100.0 MHz" [get_ports clk]

derive_clock_uncertainty

set_false_path -from [get_ports {key[*]}]  -to [all_clocks]
#set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {gpio_*}]  -to [all_clocks]

set_false_path -from * -to [get_ports {led[*]}]

set_false_path -from * -to [get_ports {gpio_*}]
