create_clock -period "50.0 MHz" [get_ports {clk*}]

derive_clock_uncertainty

set_false_path -from [get_ports {key_n[*]}] -to [all_clocks]
set_false_path -from [get_ports {sw_n[*]}]  -to [all_clocks]

set_false_path -from * -to [get_ports {led_n[*]}]

set_false_path -from * -to [get_ports {abcdefgh_n[*]}]
set_false_path -from * -to [get_ports {digit_n[*]}]

# If this signal is not commented out and is not used, it makes annoying sound
# set_false_path -from * -to buzzer

set_false_path -from * -to vga_vsync
set_false_path -from * -to vga_hsync
set_false_path -from * -to [get_ports {vga_rgb[*]}]

set_false_path -from [get_ports {gpio[*]}] -to [all_clocks]
set_false_path -from * -to [get_ports {gpio[*]}]

# set_false_path -from uart_rx -to [all_clocks]
# set_false_path -from * -to uart_tx

# ps2_clk
# ps2_data

# eeprom_sda
# eeprom_sck

# LCD1602/12864

# lcd_d0
# lcd_d1
# lcd_d2
# lcd_d3
# lcd_d4
# lcd_d5
# lcd_d6
# lcd_d7
# lcd_rs
# lcd_wr
# lcd_en

# Useful information
#
# http://land-boards.com/blwiki/index.php?title=A-C4E6_Cyclone_IV_FPGA_EP4CE6E22C8N_Development_Board
# http://land-boards.com/blwiki/index.php?title=A-C4E10_Cyclone_IV_FPGA_EP4CE10E22C8N_Development_Board
