// The timing constraints
//

create_clock -name CLK     -period 37.037 -waveform {0 18.518} [get_ports {CLK}]
create_clock -name LCD_CLK -period 111.11 -waveform {0 55.555} [get_ports {LCD_CLK}]