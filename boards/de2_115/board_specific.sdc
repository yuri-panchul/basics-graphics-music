create_clock -period "50.0 MHz" [get_ports CLOCK_50]

# for calculating divide_by value see vga_clock parameter in boards/de2_115/board_specific_top.sv

create_generated_clock -name vga_clk -divide_by 2 -source [get_ports { CLOCK_50 }] [get_registers { clk_en }]
create_generated_clock -name vga_clk_out -source [get_registers { clk_en }] [get_ports { VGA_CLK }]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from UART_RXD              -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {LEDR[*]}]

set_false_path -from * -to [get_ports {HEX0[*]}]
set_false_path -from * -to [get_ports {HEX1[*]}]
set_false_path -from * -to [get_ports {HEX2[*]}]
set_false_path -from * -to [get_ports {HEX3[*]}]
set_false_path -from * -to [get_ports {HEX4[*]}]
set_false_path -from * -to [get_ports {HEX5[*]}]
set_false_path -from * -to [get_ports {HEX6[*]}]
set_false_path -from * -to [get_ports {HEX7[*]}]

set_false_path -from * -to [get_ports {VGA_HS}]
set_false_path -from * -to [get_ports {VGA_VS}]
set_false_path -from * -to [get_ports {VGA_R[*]}]
set_false_path -from * -to [get_ports {VGA_G[*]}]
set_false_path -from * -to [get_ports {VGA_B[*]}]
set_false_path -from * -to [get_ports {VGA_BLANK_N}]
set_false_path -from * -to [get_ports {VGA_SYNC_N}]

set_false_path -from * -to [get_ports {GPIO[*]}]
