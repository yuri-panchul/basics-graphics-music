# 27 MHz board oscillator and the related 31 MHz LCD/lab clock.
create_clock -name CLK -period 37.037037 [get_ports {CLK}]
create_generated_clock -name pixel_clk -source [get_ports {CLK}] -multiply_by 31 -divide_by 27 [get_pins {i_lcd_pll/rpll_inst/CLKOUTD3}]

# LCD profile: 8 ns minimum setup/hold plus 2 ns allowance for jumper skew.
# The actual panel must meet this profile; see the timing reference in README.md.
# RGB and controls leave registers on falling pixel edges; the panel samples
# rising edges.
set_output_delay -clock pixel_clk -max 10 [get_ports {LCD_R[*] LCD_G[*] LCD_B[*] LCD_DE LCD_HS LCD_VS}]
set_output_delay -clock pixel_clk -min -10 [get_ports {LCD_R[*] LCD_G[*] LCD_B[*] LCD_DE LCD_HS LCD_VS}]

# Buttons are asynchronous. Release is synchronized in board_specific_top.
set_false_path -from [get_ports {KEY[*]}]

# UART, TM1638 and I2S external timing is not fully constrained here. Their
# protocol RTL is shared with Tang Nano 9K; verify waveforms on real hardware.
# The LCD pixel clock remains present when a lab disables graphics.
