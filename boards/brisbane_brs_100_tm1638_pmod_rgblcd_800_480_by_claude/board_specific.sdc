# The timing constraints

create_clock -name CLK -period 37.037 -waveform {0 18.518} [get_ports {pad_clk_27Mhz}]
# The 800x480 pixel clock is 32.4 MHz, see gowin_rpll.v

create_clock -name LCD_CK -period 30.864 -waveform {0 15.432} [get_ports {pad_io[9]}]
