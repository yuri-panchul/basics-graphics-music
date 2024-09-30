create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]

# for calculating divide_by value see CLK_Freq/I2C_Freq in boards/de10_nano/board_specific_top.sv

create_generated_clock -name i2c_controller_clk -divide_by 2500 -source [get_ports { FPGA_CLK1_50 }] [get_registers { I2C_HDMI_Config:i_i2c_hdmi_conf|mI2C_CTRL_CLK }]

derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from [get_ports {HDMI_*}]  -to *
set_false_path -from [get_ports {GPIO_*}]  -to [all_clocks]

set_false_path -from * -to [get_ports {LED[*]}]
set_false_path -from * -to [get_ports {HDMI_*}]
set_false_path -from * -to [get_ports {GPIO_*}]
