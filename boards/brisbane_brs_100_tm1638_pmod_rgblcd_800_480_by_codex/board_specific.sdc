# 27 MHz board oscillator and the related 31 MHz LCD/lab clock.
create_clock -name CLK -period 37.037037 [get_ports {pad_clk_27Mhz}]
create_generated_clock -name pixel_clk -source [get_ports {pad_clk_27Mhz}] -multiply_by 31 -divide_by 27 [get_pins {i_lcd_pll/rpll_inst/CLKOUTD3}]

# LCD profile: 8 ns minimum setup/hold plus 2 ns allowance for jumper skew.
# The actual panel must meet this profile; see the timing reference in README.md.
# RGB and controls leave registers on falling pixel edges; the panel samples
# rising edges.
# GPIO 1..16 carry RGB; 18/19/20 carry HS/VS/DE. GPIO 17 is the clock.
set_output_delay -clock pixel_clk -max 10 [get_ports {pad_io[1] pad_io[2] pad_io[3] pad_io[4] pad_io[5] pad_io[6] pad_io[7] pad_io[8] pad_io[9] pad_io[10] pad_io[11] pad_io[12] pad_io[13] pad_io[14] pad_io[15] pad_io[16] pad_io[18] pad_io[19] pad_io[20]}]
set_output_delay -clock pixel_clk -min -10 [get_ports {pad_io[1] pad_io[2] pad_io[3] pad_io[4] pad_io[5] pad_io[6] pad_io[7] pad_io[8] pad_io[9] pad_io[10] pad_io[11] pad_io[12] pad_io[13] pad_io[14] pad_io[15] pad_io[16] pad_io[18] pad_io[19] pad_io[20]}]

# Buttons are asynchronous. Release is synchronized in board_specific_top.
set_false_path -from [get_ports {pad_user_buttons_n[*]}]

# UART, TM1638 and I2S external timing is not fully constrained here. Their
# protocol RTL is shared with Tang Nano 9K; verify waveforms on real hardware.
# The LCD pixel clock remains present when a lab disables graphics.
