create_clock -period "50.0 MHz" [get_ports clk]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from UART_RXD              -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {LED[*]}]

set_false_path -from * -to [get_ports {SEG[*]}]
set_false_path -from * -to [get_ports {DIG[*]}]

set_false_path -from * -to [get_ports {VGA*}]

# set_false_path -from * -to UART_TXD

set_false_path -from * -to [get_ports {GPIO[*]}]
