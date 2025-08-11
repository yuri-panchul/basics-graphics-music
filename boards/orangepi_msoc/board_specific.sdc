# The timing constraints

create_clock -name CLK -period 40 -waveform {0 20} [get_ports {CLK}]
