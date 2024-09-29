create_clock -period "50.0 MHz" [get_ports {CLK*}]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY_N[*]}] -to [all_clocks]
set_false_path -from [get_ports {SW_N[*]}]  -to [all_clocks]
set_false_path -from UART_RX                -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}]  -to [all_clocks]

set_false_path -from * -to [get_ports {LED_N[*]}]

set_false_path -from * -to [get_ports {ABCDEFGH_N[*]}]
set_false_path -from * -to [get_ports {DIGIT_N[*]}]

set_false_path -from * -to VGA_VSYNC
set_false_path -from * -to VGA_HSYNC
set_false_path -from * -to [get_ports {VGA_RGB[*]}]

set_false_path -from * -to UART_TX
set_false_path -from * -to [get_ports {GPIO[*]}]

# BUZZER

# PS2_CLK
# PS2_DATA

# EEPROM_SDA
# EEPROM_SCK

# LCD1602/12864

# LCD_D0
# LCD_D1
# LCD_D2
# LCD_D3
# LCD_D4
# LCD_D5
# LCD_D6
# LCD_D7
# LCD_RS
# LCD_WR
# LCD_EN

# Useful information
#
# http://land-boards.com/blwiki/index.php?title=A-C4E6_Cyclone_IV_FPGA_EP4CE6E22C8N_Development_Board
# http://land-boards.com/blwiki/index.php?title=A-C4E10_Cyclone_IV_FPGA_EP4CE10E22C8N_Development_Board
