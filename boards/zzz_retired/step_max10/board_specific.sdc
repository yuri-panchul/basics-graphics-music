create_clock -period "12.0 MHz" [get_ports clk_in]

derive_clock_uncertainty

set_false_path -from [get_ports {BTN[*]}]     -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]      -to [all_clocks]
set_false_path -from [get_ports {GPIO*}]      -to [all_clocks]

set_false_path -from * -to [get_ports {WAT_LED[*]}]

set_false_path -from * -to [get_ports {GPIO*}]
