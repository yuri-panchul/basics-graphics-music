# The timing constraints

create_clock -name CLK -period 37.037 -waveform {0 18.518} [get_ports {pad_clk_27Mhz}]
create_clock -name LCD_CK -period 111.11 -waveform {0 55.555} [get_ports {pad_io[9]}]
