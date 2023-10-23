create_clock -period "50.0 MHz" [get_ports CLOCK_50_B8A]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from CPU_RESET_n           -to [all_clocks]
set_false_path -from UART_RX               -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}] -to [all_clocks]

# set_false_path -from * -to UART_TX

set_false_path -from * -to [get_ports {LED*}]

set_false_path -from * -to [get_ports {HEX*}]

set_false_path -from * -to [get_ports {GPIO[*]}]
