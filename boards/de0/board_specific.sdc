create_clock -period "50.0 MHz" [get_ports CLOCK_50]

derive_clock_uncertainty

set_false_path -from [get_ports {BUTTON[*]}]  -to [all_clocks]
set_false_path -from UART_RXD                 -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]      -to [all_clocks]
set_false_path -from [get_ports {GPIO*}]      -to [all_clocks]

# set_false_path -from * -to UART_TXD

set_false_path -from * -to [get_ports {LEDG[*]}]

set_false_path -from * -to [get_ports {HEX*}]

set_false_path -from * -to [get_ports {VGA_*}]

set_false_path -from * -to [get_ports {GPIO*}]
