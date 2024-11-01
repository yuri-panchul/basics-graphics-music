# The timing constraints

create_clock -name CLK        -period 37.037 -waveform {0 18.518} [get_ports {CLK}]
#create_clock -name serial_clk -period 8      -waveform {0 4}      [get_nets  {serial_clk}]
