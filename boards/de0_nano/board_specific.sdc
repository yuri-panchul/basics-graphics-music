create_clock -period "50.0 MHz" [get_ports CLOCK_50]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]       -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]        -to [all_clocks]

set_false_path -from [get_ports {GPIO_0[*]}]    -to [all_clocks]
set_false_path -from [get_ports {GPIO_0_IN[*]}] -to [all_clocks]
set_false_path -from [get_ports {GPIO_1[*]}]    -to [all_clocks]
set_false_path -from [get_ports {GPIO_1_IN[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {LED[*]}]

set_false_path -from * -to [get_ports {GPIO_0[*]}]
set_false_path -from * -to [get_ports {GPIO_0_IN[*]}]
set_false_path -from * -to [get_ports {GPIO_1[*]}]
set_false_path -from * -to [get_ports {GPIO_1_IN[*]}]
