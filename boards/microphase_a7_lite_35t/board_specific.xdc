# Clock signal

create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 5} [get_ports {CLK_50M}];

set_property PACKAGE_PIN J19 [get_ports CLK_50M]
set_property IOSTANDARD LVCMOS33 [get_ports CLK_50M]

set_property PACKAGE_PIN L18 [get_ports RESETN]
set_property IOSTANDARD LVCMOS33 [get_ports RESETN]

# KEYs

set_property PACKAGE_PIN AA1 [get_ports {KEY[0]}]
set_property PACKAGE_PIN W1 [get_ports {KEY[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {KEY[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {KEY[1]}]

# LEDs

set_property PACKAGE_PIN M18 [get_ports {LED[0]}]
set_property PACKAGE_PIN N18 [get_ports {LED[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]

# UART

set_property PACKAGE_PIN U2 [get_ports UART_RX]
set_property PACKAGE_PIN V2 [get_ports UART_TX]

set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

# HDMI

set_property PACKAGE_PIN L19 [get_ports TMDS_CLK_P]
set_property PACKAGE_PIN K21 [get_ports {TMDS_D_P[0]}]
set_property PACKAGE_PIN J20 [get_ports {TMDS_D_P[1]}]
set_property PACKAGE_PIN G17 [get_ports {TMDS_D_P[2]}]

set_property IOSTANDARD TMDS_33 [get_ports TMDS_CLK_P]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_D_P[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_D_P[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_D_P[2]}]

# GPIO

set_property PACKAGE_PIN F13 [get_ports {GPIO[0]}]
set_property PACKAGE_PIN F14 [get_ports {GPIO[1]}]
set_property PACKAGE_PIN E13 [get_ports {GPIO[2]}]
set_property PACKAGE_PIN E14 [get_ports {GPIO[3]}]
set_property PACKAGE_PIN D14 [get_ports {GPIO[4]}]
set_property PACKAGE_PIN D15 [get_ports {GPIO[5]}]
set_property PACKAGE_PIN E16 [get_ports {GPIO[6]}]
set_property PACKAGE_PIN D16 [get_ports {GPIO[7]}]
set_property PACKAGE_PIN D17 [get_ports {GPIO[8]}]
set_property PACKAGE_PIN D21 [get_ports {GPIO[9]}]
set_property PACKAGE_PIN G21 [get_ports {GPIO[10]}]
set_property PACKAGE_PIN C22 [get_ports {GPIO[11]}]
set_property PACKAGE_PIN B22 [get_ports {GPIO[12]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GPIO[*]}]