# Synthesis and Place & Route settings

# BRS-100 carries GW1NR-LV9QN88PC7/I6. Gowin EDA Education edition
# knows only GW1NR-LV9QN88PC6/I5, the part of Tang Nano 9K. It is
# the same GW1NR-9C die in a slower speed grade, so its timing
# analysis is pessimistic for BRS-100. The programmer addresses
# both parts as GW1NR-9C.
# With a licensed Gowin EDA that lists the C7/I6 part, you may use:
#
# set_device GW1NR-LV9QN88PC7/I6 -name GW1NR-9 -device_version C

set_device GW1NR-LV9QN88PC6/I5 -name GW1NR-9 -device_version C

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name fpga_project
set_option -top_module board_specific_top
set_option -verilog_std sysv2017

set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
