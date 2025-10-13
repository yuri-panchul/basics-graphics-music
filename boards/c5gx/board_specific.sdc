create_clock -period "50.0 MHz" [get_ports CLOCK_50_B8A]

# for calculating divide_by value see CLK_Freq/I2C_Freq in boards/c5gx/board_specific_top.sv

create_generated_clock -name i2c_controller_clk -divide_by 2500 -source [get_ports { CLOCK_50_B8A }] [get_registers { I2C_HDMI_Config:i_i2c_hdmi_conf|mI2C_CTRL_CLK }]

derive_clock_uncertainty

set_false_path -from CPU_RESET_n           -to [all_clocks]
set_false_path -from [get_ports {GPIO[*]}] -to [all_clocks]
set_false_path -from [get_ports {HDMI_*}]  -to *
set_false_path -from [get_ports {I2C_SDA}] -to [all_clocks]
set_false_path -from [get_ports {KEY[*]}]  -to [all_clocks]
set_false_path -from [get_ports {SW[*]}]   -to [all_clocks]
set_false_path -from UART_RX               -to [all_clocks]

# set_false_path -from * -to UART_TX

set_false_path -from * -to [get_ports {GPIO[*]}]
set_false_path -from * -to [get_ports {HEX*}]
set_false_path -from * -to [get_ports {HDMI_*}]
set_false_path -from * -to [get_ports {I2C_SCL}]
set_false_path -from * -to [get_ports {I2C_SDA}]
set_false_path -from * -to [get_ports {LED*}]
set_false_path -from * -to [get_ports {AUD_*}]
