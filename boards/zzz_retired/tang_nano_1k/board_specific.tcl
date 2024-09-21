# The synthesis options

set_device GW1NZ-LV1QN48C6/I5
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name fpga_project
set_option -top_module board_specific_top
set_option -verilog_std sysv2017
set_option -use_sspi_as_gpio 1
# set_option -cmser_mode auto

# TODO
#set_option -use_sspi_as_gpio 1
#set_option -use_mspi_as_gpio 1
#set_option -use_i2c_as_gpio  1
#set JTAG regular_io = false
#set SSPI regular_io = false
#set MSPI regular_io = false
#set READY regular_io = false
#set DONE regular_io = false
#set RECONFIG_N regular_io = false
#set I2C regular_io = false
