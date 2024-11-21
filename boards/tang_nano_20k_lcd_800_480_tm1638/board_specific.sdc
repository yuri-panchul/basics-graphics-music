// The timing constraints
create_clock -name CLK     -period 37.037 -waveform {0 18.518} [get_ports {CLK}]
create_clock -name LCD_CLK -period 30.03  -waveform {0 15.015} [get_ports {LCD_CLK}]
