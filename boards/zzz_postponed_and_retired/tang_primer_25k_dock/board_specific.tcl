# The synthesis options

set_device GW5A-LV25MG121NC1/I0 -device_version A

set_option -synthesis_tool    gowinsynthesis
set_option -output_base_name  fpga_project
set_option -top_module        board_specific_top
set_option -verilog_std       sysv2017

set_option -use_cpu_as_gpio  1
set_option -use_i2c_as_gpio  1
#set_option -use_sspi_as_gpio 1
