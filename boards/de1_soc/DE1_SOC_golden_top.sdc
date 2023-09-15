create_clock -name "clock_50_0" -period 20.000ns [get_ports {CLOCK_50}]
create_clock -name "clock_50_1" -period 20.000ns [get_ports {CLOCK2_50}]
create_clock -name "clock_50_2" -period 20.000ns [get_ports {CLOCK3_50}]
create_clock -name "clock_50_3" -period 20.000ns [get_ports {CLOCK4_50}]

derive_clock_uncertainty
