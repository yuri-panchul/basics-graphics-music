//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12 (64-bit) 
//Created Time: 2026-01-05 22:55:53
create_clock -name CLK -period 37.037 -waveform {0 18.518} [get_ports {CLK}]
create_generated_clock -name serial_clk -source [get_ports {CLK}] -master_clock CLK -divide_by 27 -multiply_by 125 [get_pins {i_Gowin_rPLL/rpll_inst/CLKOUT}]
create_generated_clock -name pixel_clk -source [get_pins {i_Gowin_rPLL/rpll_inst/CLKOUT}] -master_clock serial_clk -divide_by 5 [get_pins {i_Gowin_CLKDIV/clkdiv_inst/CLKOUT}]
