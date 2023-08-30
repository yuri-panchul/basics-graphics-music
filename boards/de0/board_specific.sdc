create_clock -period "50.0 MHz" [get_ports CLK]

derive_clock_uncertainty

set_false_path -from [get_ports {BUTTON[*]}]  -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}] -to [all_clocks]

set_false_path -from * -to [get_ports {LEDR[*]}]

set_false_path -from * -to [get_ports {HEX0_D[*]}]
set_false_path -from * -to [get_ports {HEX1_D[*]}]
set_false_path -from * -to [get_ports {HEX2_D[*]}]
set_false_path -from * -to [get_ports {HEX3_D[*]}]

set_false_path -from * -to vga_hs
set_false_path -from * -to vga_vs
set_false_path -from * -to [get_ports {VGA_R[*]}]
set_false_path -from * -to [get_ports {VGA_G[*]}]
set_false_path -from * -to [get_ports {VGA_B[*]}]

set_false_path -from * -to [get_ports {GPIO[*]}]