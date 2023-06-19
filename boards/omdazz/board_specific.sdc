create_clock -period "50.0 MHz" [get_ports clk]

derive_clock_uncertainty

set_false_path -from [get_ports {key_sw[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {led[*]}]
set_false_path -from * -to [get_ports {abcdefgh[*]}]
set_false_path -from * -to [get_ports {digit[*]}]
set_false_path -from * -to buzzer
set_false_path -from * -to hsync
set_false_path -from * -to vsync
set_false_path -from * -to [get_ports {rgb[*]}]
