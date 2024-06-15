# Synthesis and Place & Route settings

set_device GW1NR-LV9QN88PC6/I5 -name GW1NR-9 -device_version C

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name fpga_project
set_option -top_module board_specific_top
set_option -verilog_std sysv2017

set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
