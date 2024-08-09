# Synthesis and Place & Route settings

set_device GW5AST-LV138FPG676AES -name GW5AST-138 -device_version B
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name fpga_project
set_option -top_module board_specific_top
set_option -verilog_std sysv2017

set_option -use_cpu_as_gpio  1
set_option -use_sspi_as_gpio 1
