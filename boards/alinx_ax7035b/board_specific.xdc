############## NET - IOSTANDARD ##################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design] 
############## clock and reset define##################
create_clock -period 20 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports {sys_clk}]
set_property PACKAGE_PIN Y18 [get_ports {sys_clk}]

set_property IOSTANDARD LVCMOS33 [get_ports {rst_n}]
set_property PACKAGE_PIN F20 [get_ports {rst_n}]
############## key define##############################
set_property PACKAGE_PIN M13 [get_ports {key_in[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[0]}]

set_property PACKAGE_PIN K14 [get_ports {key_in[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[1]}]

set_property PACKAGE_PIN K13 [get_ports {key_in[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[2]}]

set_property PACKAGE_PIN L13 [get_ports {key_in[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[3]}]
#############LED Setting#############################
set_property PACKAGE_PIN F19 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN E21 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN D20 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN C20 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
#######################digital tube setting#############
set_property PACKAGE_PIN J5 [get_ports {SMG_Data[0]}]
set_property PACKAGE_PIN M3 [get_ports {SMG_Data[1]}]
set_property PACKAGE_PIN J6 [get_ports {SMG_Data[2]}]
set_property PACKAGE_PIN H5 [get_ports {SMG_Data[3]}]
set_property PACKAGE_PIN G4 [get_ports {SMG_Data[4]}]
set_property PACKAGE_PIN K6 [get_ports {SMG_Data[5]}]
set_property PACKAGE_PIN K3 [get_ports {SMG_Data[6]}]
set_property PACKAGE_PIN H4 [get_ports {SMG_Data[7]}]

set_property PACKAGE_PIN M2 [get_ports {Scan_Sig[0]}]
set_property PACKAGE_PIN N4 [get_ports {Scan_Sig[1]}]
set_property PACKAGE_PIN L5 [get_ports {Scan_Sig[2]}]
set_property PACKAGE_PIN L4 [get_ports {Scan_Sig[3]}]
set_property PACKAGE_PIN M16 [get_ports {Scan_Sig[4]}]
set_property PACKAGE_PIN M17 [get_ports {Scan_Sig[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {SMG_Data[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Scan_Sig[*]}]
############## HDMIOUT define#########################
#set_property IOSTANDARD TMDS_33 [get_ports TMDS_clk_n]
#
#set_property PACKAGE_PIN E1 [get_ports TMDS_clk_p]
#set_property IOSTANDARD TMDS_33 [get_ports TMDS_clk_p]
#
#set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[0]}]
#
#set_property PACKAGE_PIN G1 [get_ports {TMDS_data_p[0]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[0]}]
#
#set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[1]}]
#
#set_property PACKAGE_PIN H2 [get_ports {TMDS_data_p[1]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[1]}]
#
#set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[2]}]
#
#set_property PACKAGE_PIN K1 [get_ports {TMDS_data_p[2]}]
#set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[2]}]
#
#set_property PACKAGE_PIN M6 [get_ports {HDMI_OEN[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {HDMI_OEN[0]}]
############## usb uart define########################
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PACKAGE_PIN G15 [get_ports uart_rx]

set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property PACKAGE_PIN G16 [get_ports uart_tx]
############## TODO: GPIO define########################

# J9
#
#  1 GND    2 +5V
#  3 D16    4 E16
#  5 F14    6 F13
#  7 E14    8 E13
#  9 D15   10 D14
# 11 B13   12 C13
# 13 A14   14 A13
# 15 C15   16 C14
# 17 A16   18 A15
# 19 B16   20 B15
# 21 B18   22 B17
# 23 A19   24 A18
# 25 C19   26 C18
# 27 A20   28 B20
# 29 C17   30 D17
# 31 D19   32 E19
# 33 E18   34 F18
# 35 E17   36 F16
# 37 GND   38 GND
# 39 +3.3V 40 +3.3V

# J10
#
#  1 GND    2 +5V
#  3 P17    4 N17
#  5 R19    6 P19
#  7 T18    8 R18
#  9 U21   10 T21
# 11 V22   12 U22
# 13 V20   14 U20
# 15 W22   16 W21
# 17 Y22   18 Y21
# 19 AA21  20 AA20
# 21 AB22  22 AB21
# 23 AB20  24 AA19
# 25 W20   26 W19
# 27 AB18  28 AA18
# 29 V19   30 V18
# 31 W17   32 V17
# 33 U18   34 U17
# 35 R14   36 P14
# 37 GND   38 GND
# 39 +3.3V 40 +3.3V
