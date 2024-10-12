// The timing constraints

create_clock -name CLK -period 20 -waveform {0 10} [get_ports {CLK}]
