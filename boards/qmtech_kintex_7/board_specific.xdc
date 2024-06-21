create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 5} [get_ports {CLK_IN}];

set_property IOSTANDARD LVCMOS33 [get_ports CLK_IN]
set_property IOSTANDARD LVCMOS18 [get_ports RST_IN]
set_property PACKAGE_PIN F22 [get_ports CLK_IN]
set_property PACKAGE_PIN AF9 [get_ports RST_IN]



set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT_A}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT_B}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT_C}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT_D}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT_E}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_OUT_F}]

set_property PACKAGE_PIN D10 [get_ports {LED_OUT_A}]
set_property PACKAGE_PIN A10 [get_ports {LED_OUT_B}]
set_property PACKAGE_PIN B9 [get_ports {LED_OUT_C}]
set_property PACKAGE_PIN A8 [get_ports {LED_OUT_D}]
set_property PACKAGE_PIN J26 [get_ports {LED_OUT_E}]
set_property PACKAGE_PIN H26 [get_ports {LED_OUT_F}]



set_property IOSTANDARD LVCMOS33 [get_ports {AN}]
set_property IOSTANDARD LVCMOS33 [get_ports {BN}]
set_property IOSTANDARD LVCMOS33 [get_ports {CN}]
set_property IOSTANDARD LVCMOS33 [get_ports {DN}]

set_property PACKAGE_PIN E10 [get_ports {AN}]
set_property PACKAGE_PIN B10 [get_ports {BN}]
set_property PACKAGE_PIN C9 [get_ports {CN}]
set_property PACKAGE_PIN A9 [get_ports {DN}]



set_property IOSTANDARD LVCMOS33 [get_ports {CA}]
set_property IOSTANDARD LVCMOS33 [get_ports {CB}]
set_property IOSTANDARD LVCMOS33 [get_ports {CC}]
set_property IOSTANDARD LVCMOS33 [get_ports {CD}]
set_property IOSTANDARD LVCMOS33 [get_ports {CD}]
set_property IOSTANDARD LVCMOS33 [get_ports {CD}]
set_property IOSTANDARD LVCMOS33 [get_ports {CE}]
set_property IOSTANDARD LVCMOS33 [get_ports {CF}]
set_property IOSTANDARD LVCMOS33 [get_ports {CG}]
set_property IOSTANDARD LVCMOS33 [get_ports {DP}]

set_property PACKAGE_PIN D16 [get_ports {CA}]
set_property PACKAGE_PIN A15 [get_ports {CB}]
set_property PACKAGE_PIN C13 [get_ports {CC}]
set_property PACKAGE_PIN A14 [get_ports {CD}]
set_property PACKAGE_PIN D13 [get_ports {CE}]
set_property PACKAGE_PIN A12 [get_ports {CF}]
set_property PACKAGE_PIN C11 [get_ports {CG}]
set_property PACKAGE_PIN B11 [get_ports {DP}]



set_property IOSTANDARD LVCMOS33 [get_ports {BTN_A}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_B}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_C}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_D}]
set_property IOSTANDARD LVCMOS18 [get_ports {BTN_E}]

set_property PACKAGE_PIN D14 [get_ports {BTN_A}]
set_property PACKAGE_PIN A13 [get_ports {BTN_B}]
set_property PACKAGE_PIN C12 [get_ports {BTN_C}]
set_property PACKAGE_PIN B12 [get_ports {BTN_D}]
set_property PACKAGE_PIN AF10 [get_ports {BTN_E}]



#set_property DCI_CASCADE {34} [get_iobanks 34]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
