# BRS-100 manufacturer target: GW1NR-9, revision C, QFN88P, C7/I6.
# Older Education device databases may only list the Tang Nano C6/I5 part.
# Do not silently change the device to make those installations accept it.

set_device GW1NR-LV9QN88PC7/I6 -name GW1NR-9 -device_version C

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name fpga_project
set_option -top_module board_specific_top
set_option -verilog_std sysv2017
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1

# Placement/routing settings used by BrisbaneSilicon's reference project.
set_option -place_option 2
set_option -route_option 1
set_option -replicate_resources 1
