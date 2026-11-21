create_clock -period "50.0 MHz" [get_ports CLK]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY_N[*]}] -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}]  -to [all_clocks]

set_false_path -from * -to [get_ports {LED_N[*]}]

set_false_path -from * -to [get_ports {ABCDEFGH_N[*]}]
set_false_path -from * -to [get_ports {DIGIT_N[*]}]

set_false_path -from * -to [get_ports {VGA*}]

set_false_path -from * -to [get_ports {GPIO[*]}]
