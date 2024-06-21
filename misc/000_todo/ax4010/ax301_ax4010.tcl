# Copyright (C) 2017  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions
# and other software and tools, and its AMPP partner logic
# functions, and any output files from any of the foregoing
# (including device programming or simulation files), and any
# associated documentation or information are expressly subject
# to the terms and conditions of the Intel Program License
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details.

# Quartus Prime Version 17.1.0 Build 590 10/25/2017 SJ Lite Edition
# File: ...\ax301_ax4010.tcl
# Generated on: Thu Apr 19 14:08:57 2018

package require ::quartus::project
#clock 50m
set_location_assignment PIN_E1 -to clk
#key
set_location_assignment PIN_N13 -to rst_n
set_location_assignment PIN_M15 -to key2
set_location_assignment PIN_M16 -to key3
set_location_assignment PIN_E16 -to key4
#led
set_location_assignment PIN_D9  -to led[3]
set_location_assignment PIN_C9  -to led[2]
set_location_assignment PIN_F9  -to led[1]
set_location_assignment PIN_E10 -to led[0]
#ds1302 rtc
set_location_assignment PIN_P6 -to rtc_sclk
set_location_assignment PIN_M8 -to rtc_data
set_location_assignment PIN_N8 -to rtc_ce
#uart
set_location_assignment PIN_M2 -to uart_rx
set_location_assignment PIN_N1 -to uart_tx
#eeprom
set_location_assignment PIN_D1 -to i2c_scl
set_location_assignment PIN_E6 -to i2c_sda
#spi flash
set_location_assignment PIN_H1 -to dclk
set_location_assignment PIN_H2 -to miso
set_location_assignment PIN_C1 -to mosi
set_location_assignment PIN_D2 -to ncs
#buzzer
set_location_assignment PIN_C11 -to buzzer
#SD card spi pins
set_location_assignment PIN_D12 -to SD_DCLK
set_location_assignment PIN_E15 -to SD_MISO
set_location_assignment PIN_F10 -to SD_MOSI
set_location_assignment PIN_D11 -to SD_nCS
#sdram
set_location_assignment PIN_F15 -to sdram_addr[12]
set_location_assignment PIN_D16 -to sdram_addr[11]
set_location_assignment PIN_F14 -to sdram_addr[10]
set_location_assignment PIN_D15 -to sdram_addr[9]
set_location_assignment PIN_C16 -to sdram_addr[8]
set_location_assignment PIN_C15 -to sdram_addr[7]
set_location_assignment PIN_B16 -to sdram_addr[6]
set_location_assignment PIN_A15 -to sdram_addr[5]
set_location_assignment PIN_A14 -to sdram_addr[4]
set_location_assignment PIN_C14 -to sdram_addr[3]
set_location_assignment PIN_D14 -to sdram_addr[2]
set_location_assignment PIN_E11 -to sdram_addr[1]
set_location_assignment PIN_F11 -to sdram_addr[0]
set_location_assignment PIN_F13 -to sdram_ba[1]
set_location_assignment PIN_G11 -to sdram_ba[0]
set_location_assignment PIN_J12 -to sdram_cas_n
set_location_assignment PIN_F16 -to sdram_cke
set_location_assignment PIN_B14 -to sdram_clk
set_location_assignment PIN_K10 -to sdram_cs_n
set_location_assignment PIN_L15 -to sdram_dq[15]
set_location_assignment PIN_L16 -to sdram_dq[14]
set_location_assignment PIN_K15 -to sdram_dq[13]
set_location_assignment PIN_K16 -to sdram_dq[12]
set_location_assignment PIN_J15 -to sdram_dq[11]
set_location_assignment PIN_J16 -to sdram_dq[10]
set_location_assignment PIN_J11 -to sdram_dq[9]
set_location_assignment PIN_G16 -to sdram_dq[8]
set_location_assignment PIN_K12 -to sdram_dq[7]
set_location_assignment PIN_L11 -to sdram_dq[6]
set_location_assignment PIN_L14 -to sdram_dq[5]
set_location_assignment PIN_L13 -to sdram_dq[4]
set_location_assignment PIN_L12 -to sdram_dq[3]
set_location_assignment PIN_N14 -to sdram_dq[2]
set_location_assignment PIN_M12 -to sdram_dq[1]
set_location_assignment PIN_P14 -to sdram_dq[0]
set_location_assignment PIN_G15 -to sdram_dqm[1]
set_location_assignment PIN_J14 -to sdram_dqm[0]
set_location_assignment PIN_K11 -to sdram_ras_n
set_location_assignment PIN_J13 -to sdram_we_n
#ov5640
set_location_assignment PIN_J2 -to cmos_db[7]
set_location_assignment PIN_J1 -to cmos_db[6]
set_location_assignment PIN_N5 -to cmos_db[5]
set_location_assignment PIN_L1 -to cmos_db[4]
set_location_assignment PIN_M1 -to cmos_db[3]
set_location_assignment PIN_G2 -to cmos_db[2]
set_location_assignment PIN_M6 -to cmos_db[1]
set_location_assignment PIN_L2 -to cmos_db[0]
set_location_assignment PIN_G1 -to cmos_pclk
set_location_assignment PIN_F1 -to cmos_scl
set_location_assignment PIN_F3 -to cmos_sda
set_location_assignment PIN_F2 -to cmos_vsync
set_location_assignment PIN_K2 -to cmos_xclk
set_location_assignment PIN_K1 -to cmos_href
set_location_assignment PIN_N6 -to cmos_rst_n
set_location_assignment PIN_M7 -to cmos_pwdn
#segment led
set_location_assignment PIN_R16 -to seg_data[7]
set_location_assignment PIN_N15 -to seg_data[6]
set_location_assignment PIN_N12 -to seg_data[5]
set_location_assignment PIN_P15 -to seg_data[4]
set_location_assignment PIN_T15 -to seg_data[3]
set_location_assignment PIN_P16 -to seg_data[2]
set_location_assignment PIN_N16 -to seg_data[1]
set_location_assignment PIN_R14 -to seg_data[0]
set_location_assignment PIN_M11 -to seg_sel[5]
set_location_assignment PIN_P11 -to seg_sel[4]
set_location_assignment PIN_N11 -to seg_sel[3]
set_location_assignment PIN_M10 -to seg_sel[2]
set_location_assignment PIN_P9  -to seg_sel[1]
set_location_assignment PIN_N9  -to seg_sel[0]
#VGA
set_location_assignment PIN_F6 -to vga_out_b[4]
set_location_assignment PIN_E5 -to vga_out_b[3]
set_location_assignment PIN_D3 -to vga_out_b[2]
set_location_assignment PIN_D4 -to vga_out_b[1]
set_location_assignment PIN_C3 -to vga_out_b[0]
set_location_assignment PIN_J6 -to vga_out_g[5]
set_location_assignment PIN_L8 -to vga_out_g[4]
set_location_assignment PIN_K8 -to vga_out_g[3]
set_location_assignment PIN_F7 -to vga_out_g[2]
set_location_assignment PIN_G5 -to vga_out_g[1]
set_location_assignment PIN_F5 -to vga_out_g[0]
set_location_assignment PIN_L6 -to vga_out_hs
set_location_assignment PIN_L4 -to vga_out_r[4]
set_location_assignment PIN_L3 -to vga_out_r[3]
set_location_assignment PIN_L7 -to vga_out_r[2]
set_location_assignment PIN_K5 -to vga_out_r[1]
set_location_assignment PIN_K6 -to vga_out_r[0]
set_location_assignment PIN_N3 -to vga_out_vs

#AN430 lcd on J2 expand port
# set_location_assignment PIN_B10 -to lcd_b[0]
# set_location_assignment PIN_A9  -to lcd_b[1]
# set_location_assignment PIN_B11 -to lcd_b[2]
# set_location_assignment PIN_A10 -to lcd_b[3]
# set_location_assignment PIN_B12 -to lcd_b[4]
# set_location_assignment PIN_A11 -to lcd_b[5]
# set_location_assignment PIN_B13 -to lcd_b[6]
# set_location_assignment PIN_A12 -to lcd_b[7]
# set_location_assignment PIN_D5  -to lcd_dclk
# set_location_assignment PIN_D6  -to lcd_de
# set_location_assignment PIN_B6  -to lcd_g[0]
# set_location_assignment PIN_A5  -to lcd_g[1]
# set_location_assignment PIN_B7  -to lcd_g[2]
# set_location_assignment PIN_A6  -to lcd_g[3]
# set_location_assignment PIN_B8  -to lcd_g[4]
# set_location_assignment PIN_A7  -to lcd_g[5]
# set_location_assignment PIN_B9  -to lcd_g[6]
# set_location_assignment PIN_A8  -to lcd_g[7]
# set_location_assignment PIN_A13 -to lcd_hs
# set_location_assignment PIN_B1  -to lcd_r[0]
# set_location_assignment PIN_C2  -to lcd_r[1]
# set_location_assignment PIN_B3  -to lcd_r[2]
# set_location_assignment PIN_A2  -to lcd_r[3]
# set_location_assignment PIN_B4  -to lcd_r[4]
# set_location_assignment PIN_A3  -to lcd_r[5]
# set_location_assignment PIN_B5  -to lcd_r[6]
# set_location_assignment PIN_A4  -to lcd_r[7]
# set_location_assignment PIN_C6  -to lcd_vs

#AN070 lcd on J2 expand port
# set_location_assignment PIN_B9  -to lcd_b[7]
# set_location_assignment PIN_A8  -to lcd_b[6]
# set_location_assignment PIN_B8  -to lcd_b[5]
# set_location_assignment PIN_A7  -to lcd_b[4]
# set_location_assignment PIN_B7  -to lcd_b[3]
# set_location_assignment PIN_A6  -to lcd_b[2]
# set_location_assignment PIN_B6  -to lcd_b[1]
# set_location_assignment PIN_A5  -to lcd_b[0]
# set_location_assignment PIN_B5  -to lcd_dclk
# set_location_assignment PIN_A4  -to lcd_de
# set_location_assignment PIN_B13 -to lcd_g[7]
# set_location_assignment PIN_A12 -to lcd_g[6]
# set_location_assignment PIN_B12 -to lcd_g[5]
# set_location_assignment PIN_A11 -to lcd_g[4]
# set_location_assignment PIN_B11 -to lcd_g[3]
# set_location_assignment PIN_A10 -to lcd_g[2]
# set_location_assignment PIN_B10 -to lcd_g[1]
# set_location_assignment PIN_A9  -to lcd_g[0]
# set_location_assignment PIN_B4  -to lcd_hs
# set_location_assignment PIN_D8  -to lcd_r[7]
# set_location_assignment PIN_C8  -to lcd_r[6]
# set_location_assignment PIN_F8  -to lcd_r[5]
# set_location_assignment PIN_E7  -to lcd_r[4]
# set_location_assignment PIN_C6  -to lcd_r[3]
# set_location_assignment PIN_D6  -to lcd_r[2]
# set_location_assignment PIN_D5  -to lcd_r[1]
# set_location_assignment PIN_A13 -to lcd_r[0]
# set_location_assignment PIN_A3  -to lcd_vs
# set_location_assignment PIN_C2  -to lcd_pwm

#AN831 audio WM8371 on J2 expand port
# set_location_assignment PIN_B4 -to wm8731_adcdat
# set_location_assignment PIN_A2 -to wm8731_bclk
# set_location_assignment PIN_B3 -to wm8731_dacdat
# set_location_assignment PIN_A3 -to wm8731_daclrc
# set_location_assignment PIN_B1 -to wm8731_scl
# set_location_assignment PIN_C2 -to wm8731_sda
# set_location_assignment PIN_B5 -to wm8731_adclrc

#AN926 ad9226 on J1 expand port
# set_location_assignment PIN_R7  -to ad9226_data_ch0[0]
# set_location_assignment PIN_T9  -to ad9226_data_ch0[1]
# set_location_assignment PIN_R8  -to ad9226_data_ch0[2]
# set_location_assignment PIN_T10 -to ad9226_data_ch0[3]
# set_location_assignment PIN_R9  -to ad9226_data_ch0[4]
# set_location_assignment PIN_T11 -to ad9226_data_ch0[5]
# set_location_assignment PIN_R10 -to ad9226_data_ch0[6]
# set_location_assignment PIN_T12 -to ad9226_data_ch0[7]
# set_location_assignment PIN_R11 -to ad9226_data_ch0[8]
# set_location_assignment PIN_T13 -to ad9226_data_ch0[9]
# set_location_assignment PIN_R12 -to ad9226_data_ch0[10]
# set_location_assignment PIN_T14 -to ad9226_data_ch0[11]
# set_location_assignment PIN_L9  -to ad9226_data_ch1[0]
# set_location_assignment PIN_T2  -to ad9226_data_ch1[1]
# set_location_assignment PIN_M9  -to ad9226_data_ch1[2]
# set_location_assignment PIN_T3  -to ad9226_data_ch1[3]
# set_location_assignment PIN_P3  -to ad9226_data_ch1[4]
# set_location_assignment PIN_T4  -to ad9226_data_ch1[5]
# set_location_assignment PIN_R3  -to ad9226_data_ch1[6]
# set_location_assignment PIN_T5  -to ad9226_data_ch1[7]
# set_location_assignment PIN_R4  -to ad9226_data_ch1[8]
# set_location_assignment PIN_T6  -to ad9226_data_ch1[9]
# set_location_assignment PIN_R5  -to ad9226_data_ch1[10]
# set_location_assignment PIN_T7  -to ad9226_data_ch1[11]
# set_location_assignment PIN_R13 -to ad9226_clk_ch0
# set_location_assignment PIN_R6  -to ad9226_clk_ch1

#AN706 ad7606 on J1 expand port
# set_location_assignment PIN_T11 -to ad7606_busy
# set_location_assignment PIN_T13 -to ad7606_convstab
# set_location_assignment PIN_R10 -to ad7606_cs
# set_location_assignment PIN_T8  -to ad7606_data[0]
# set_location_assignment PIN_R7  -to ad7606_data[1]
# set_location_assignment PIN_T7  -to ad7606_data[2]
# set_location_assignment PIN_R6  -to ad7606_data[3]
# set_location_assignment PIN_T6  -to ad7606_data[4]
# set_location_assignment PIN_R5  -to ad7606_data[5]
# set_location_assignment PIN_T5  -to ad7606_data[6]
# set_location_assignment PIN_R4  -to ad7606_data[7]
# set_location_assignment PIN_T4  -to ad7606_data[8]
# set_location_assignment PIN_R3  -to ad7606_data[9]
# set_location_assignment PIN_T3  -to ad7606_data[10]
# set_location_assignment PIN_P3  -to ad7606_data[11]
# set_location_assignment PIN_T2  -to ad7606_data[12]
# set_location_assignment PIN_M9  -to ad7606_data[13]
# set_location_assignment PIN_L10 -to ad7606_data[14]
# set_location_assignment PIN_L9  -to ad7606_data[15]
# set_location_assignment PIN_R13 -to ad7606_os[0]
# set_location_assignment PIN_T14 -to ad7606_os[1]
# set_location_assignment PIN_R12 -to ad7606_os[2]
# set_location_assignment PIN_T12 -to ad7606_rd
# set_location_assignment PIN_R11 -to ad7606_reset
# set_location_assignment PIN_R9  -to ad7606_first_data

#AN108 adda on J1 expand port
# set_location_assignment PIN_L10 -to ad9280_clk
# set_location_assignment PIN_M9  -to ad9280_data[7]
# set_location_assignment PIN_T2  -to ad9280_data[6]
# set_location_assignment PIN_P3  -to ad9280_data[5]
# set_location_assignment PIN_T3  -to ad9280_data[4]
# set_location_assignment PIN_R3  -to ad9280_data[3]
# set_location_assignment PIN_T4  -to ad9280_data[2]
# set_location_assignment PIN_R4  -to ad9280_data[1]
# set_location_assignment PIN_T5  -to ad9280_data[0]
# set_location_assignment PIN_T13 -to ad9708_clk
# set_location_assignment PIN_R12 -to ad9708_data[7]
# set_location_assignment PIN_T12 -to ad9708_data[6]
# set_location_assignment PIN_R11 -to ad9708_data[5]
# set_location_assignment PIN_T11 -to ad9708_data[4]
# set_location_assignment PIN_R10 -to ad9708_data[3]
# set_location_assignment PIN_T10 -to ad9708_data[2]
# set_location_assignment PIN_R9  -to ad9708_data[1]
# set_location_assignment PIN_T9  -to ad9708_data[0]