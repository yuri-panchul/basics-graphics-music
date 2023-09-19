create_clock -period "50.0 MHz" [get_ports clk_12]
create_clock -period "50.0 MHz" [get_ports clk_14]
create_clock -period "50.0 MHz" [get_ports clk_62]
create_clock -period "50.0 MHz" [get_ports clk_64]

derive_clock_uncertainty

set_false_path -from * -to [get_ports {pin[*]}]
set_false_path -from [get_ports {pin[*]}] -to [all_clocks]
