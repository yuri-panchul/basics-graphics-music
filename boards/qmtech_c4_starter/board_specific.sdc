create_clock -period "50.0 MHz" [get_ports CLK]

derive_clock_uncertainty

set_false_path -from [get_ports KEY]     -to [all_clocks]
set_false_path -from [get_ports UART_RX] -to [all_clocks]

set_false_path -from * -to [get_ports LED]

set_false_path -from * -to [get_ports {ABCDEFGH_N[*]}]
set_false_path -from * -to [get_ports {DIGIT_N[*]}]

set_false_path -from * -to [get_ports VGA_HSYNC]
set_false_path -from * -to [get_ports VGA_VSYNC]

set_false_path -from * -to [get_ports {VGA_RED[*]}]
set_false_path -from * -to [get_ports {VGA_GREEN[*]}]
set_false_path -from * -to [get_ports {VGA_BLUE[*]}]
