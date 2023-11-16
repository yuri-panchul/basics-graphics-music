#xc7a35ticsg324-1l

## This file is a general .xdc for the Arty A7-35 Rev. D and Rev. E
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK100MHZ]

## Switches
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {SW[0]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {SW[1]}]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {SW[2]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {SW[3]}]

## RGB LEDs
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports LED0_B]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports LED0_G]
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports LED0_R]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports LED1_B]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports LED1_G]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports LED1_R]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports LED2_B]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports LED2_G]
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports LED2_R]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports LED3_B]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports LED3_G]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports LED3_R]

## LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

## Buttons
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports CPU_RESETN]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports BTN_0]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports BTN_1]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports BTN_2]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports BTN_3]

## Pmod Header JA
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { JA[0] }]; #IO_0_15 Sch=ja[1]
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { JA[1] }]; #IO_L4N_T0_15 Sch=ja[2]
set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { JA[2] }]; #IO_L4N_T0_15 Sch=ja[3]
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { JA[3] }]; #IO_L6P_T0_15 Sch=ja[4]
set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { JA[4] }]; #IO_L6N_T0_VREF_15 Sch=ja[7]
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { JA[5] }]; #IO_L10P_T1_AD11P_15 Sch=ja[8]
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { JA[6] }]; #IO_L10N_T1_AD11N_15 Sch=ja[9]
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { JA[7] }]; #IO_25_15 Sch=ja[10]

##Pmod Header JB

set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports {JB[0]}]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports {JB[1]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {JB[2]}]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {JB[3]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {JB[4]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {JB[5]}]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {JB[6]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {JB[7]}]

##Pmod Header JC

set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {JC[0]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {JC[1]}]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports {JC[2]}]; #IO_L21P_T3_DQS_14 Sch=jc_p[2]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {JC[3]}]; #IO_L21N_T3_DQS_A06_D22_14 Sch=jc_n[2]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {JC[4]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {JC[5]}]
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports {JC[6]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {JC[7]}]


## Pmod Header JD
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { JD[0] }]; #IO_L11N_T1_SRCC_35 Sch=jd[1]
set_property -dict { PACKAGE_PIN D3    IOSTANDARD LVCMOS33 } [get_ports { JD[1] }]; #IO_L12N_T1_MRCC_35 Sch=jd[2]
set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33 } [get_ports { JD[2] }]; #IO_L13P_T2_MRCC_35 Sch=jd[3]
set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33 } [get_ports { JD[3] }]; #IO_L13N_T2_MRCC_35 Sch=jd[4]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {JD[4]}]
set_property -dict { PACKAGE_PIN D2    IOSTANDARD LVCMOS33 } [get_ports { JD[5] }]; #IO_L14N_T2_SRCC_35 Sch=jd[8]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {JD[6]}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {JD[7]}]

## USB-UART Interface
#set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports UART_TXD_IN]

## ChipKit Outer Digital Header
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {GPIO[0]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {GPIO[1]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {GPIO[2]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {GPIO[3]}]
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports {GPIO[4]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {GPIO[5]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {GPIO[6]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {GPIO[7]}]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {GPIO[8]}]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {GPIO[9]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {GPIO[10]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {GPIO[11]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {GPIO[12]}]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports {GPIO[13]}]

## ChipKit Inner Digital Header
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports {GPIO[26]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {GPIO[27]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {GPIO[28]}]
set_property -dict {PACKAGE_PIN R10 IOSTANDARD LVCMOS33} [get_ports {GPIO[29]}]
set_property -dict {PACKAGE_PIN R11 IOSTANDARD LVCMOS33} [get_ports {GPIO[30]}]
set_property -dict {PACKAGE_PIN R13 IOSTANDARD LVCMOS33} [get_ports {GPIO[31]}]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports {GPIO[32]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {GPIO[33]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {GPIO[34]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {GPIO[35]}]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {GPIO[36]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {GPIO[37]}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports {GPIO[38]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {GPIO[39]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {GPIO[40]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {GPIO[41]}]

## ChipKit Outer Analog Header - as Single-Ended Analog Inputs
## NOTE: These ports can be used as single-ended analog inputs with voltages from 0-3.3V (ChipKit analog pins A0-A5) or as digital I/O.
## WARNING: Do not use both sets of constraints at the same time!
## NOTE: The following constraints should be used with the XADC IP core when using these ports as analog inputs.
#set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { vaux4_n  }]; #IO_L1N_T0_AD4N_35 		Sch=ck_an_n[0]	ChipKit pin=A0
#set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { vaux4_p  }]; #IO_L1P_T0_AD4P_35 		Sch=ck_an_p[0]	ChipKit pin=A0
#set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { vaux5_n  }]; #IO_L3N_T0_DQS_AD5N_35 	Sch=ck_an_n[1]	ChipKit pin=A1
#set_property -dict { PACKAGE_PIN A6    IOSTANDARD LVCMOS33 } [get_ports { vaux5_p  }]; #IO_L3P_T0_DQS_AD5P_35 	Sch=ck_an_p[1]	ChipKit pin=A1
#set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { vaux6_n  }]; #IO_L7N_T1_AD6N_35 		Sch=ck_an_n[2]	ChipKit pin=A2
#set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { vaux6_p  }]; #IO_L7P_T1_AD6P_35 		Sch=ck_an_p[2]	ChipKit pin=A2
#set_property -dict { PACKAGE_PIN A1    IOSTANDARD LVCMOS33 } [get_ports { vaux7_n  }]; #IO_L9N_T1_DQS_AD7N_35 	Sch=ck_an_n[3]	ChipKit pin=A3
#set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33 } [get_ports { vaux7_p  }]; #IO_L9P_T1_DQS_AD7P_35 	Sch=ck_an_p[3]	ChipKit pin=A3
#set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33 } [get_ports { vaux15_n }]; #IO_L10N_T1_AD15N_35 	Sch=ck_an_n[4]	ChipKit pin=A4
#set_property -dict { PACKAGE_PIN B3    IOSTANDARD LVCMOS33 } [get_ports { vaux15_p }]; #IO_L10P_T1_AD15P_35 	Sch=ck_an_p[4]	ChipKit pin=A4
#set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { vaux0_n  }]; #IO_L1N_T0_AD0N_15 		Sch=ck_an_n[5]	ChipKit pin=A5
#set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { vaux0_p  }]; #IO_L1P_T0_AD0P_15 		Sch=ck_an_p[5]	ChipKit pin=A5
## ChipKit Outer Analog Header - as Digital I/O
## NOTE: the following constraints should be used when using these ports as digital I/O.
#set_property -dict { PACKAGE_PIN F5    IOSTANDARD LVCMOS33 } [get_ports { ck_a0 }]; #IO_0_35           	Sch=ck_a[0]		ChipKit pin=A0
#set_property -dict { PACKAGE_PIN D8    IOSTANDARD LVCMOS33 } [get_ports { ck_a1 }]; #IO_L4P_T0_35      	Sch=ck_a[1]		ChipKit pin=A1
#set_property -dict { PACKAGE_PIN C7    IOSTANDARD LVCMOS33 } [get_ports { ck_a2 }]; #IO_L4N_T0_35      	Sch=ck_a[2]		ChipKit pin=A2
#set_property -dict { PACKAGE_PIN E7    IOSTANDARD LVCMOS33 } [get_ports { ck_a3 }]; #IO_L6P_T0_35      	Sch=ck_a[3]		ChipKit pin=A3
#set_property -dict { PACKAGE_PIN D7    IOSTANDARD LVCMOS33 } [get_ports { ck_a4 }]; #IO_L6N_T0_VREF_35 	Sch=ck_a[4]		ChipKit pin=A4
#set_property -dict { PACKAGE_PIN D5    IOSTANDARD LVCMOS33 } [get_ports { ck_a5 }]; #IO_L11P_T1_SRCC_35	Sch=ck_a[5]		ChipKit pin=A5

## ChipKit Inner Analog Header - as Differential Analog Inputs
## NOTE: These ports can be used as differential analog inputs with voltages from 0-1.0V (ChipKit Analog pins A6-A11) or as digital I/O.
## WARNING: Do not use both sets of constraints at the same time!
## NOTE: The following constraints should be used with the XADC core when using these ports as analog inputs.
#set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { vaux12_p }]; #IO_L2P_T0_AD12P_35	Sch=ad_p[12]	ChipKit pin=A6
#set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { vaux12_n }]; #IO_L2N_T0_AD12N_35	Sch=ad_n[12]	ChipKit pin=A7
#set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { vaux13_p }]; #IO_L5P_T0_AD13P_35	Sch=ad_p[13]	ChipKit pin=A8
#set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { vaux13_n }]; #IO_L5N_T0_AD13N_35	Sch=ad_n[13]	ChipKit pin=A9
#set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { vaux14_p }]; #IO_L8P_T1_AD14P_35	Sch=ad_p[14]	ChipKit pin=A10
#set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { vaux14_n }]; #IO_L8N_T1_AD14N_35	Sch=ad_n[14]	ChipKit pin=A11
## ChipKit Inner Analog Header - as Digital I/O
## NOTE: the following constraints should be used when using the inner analog header ports as digital I/O.
#set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { ck_io20 }]; #IO_L2P_T0_AD12P_35	Sch=ad_p[12]	ChipKit pin=A6
#set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { ck_io21 }]; #IO_L2N_T0_AD12N_35	Sch=ad_n[12]	ChipKit pin=A7
#set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { ck_io22 }]; #IO_L5P_T0_AD13P_35	Sch=ad_p[13]	ChipKit pin=A8
#set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { ck_io23 }]; #IO_L5N_T0_AD13N_35	Sch=ad_n[13]	ChipKit pin=A9
#set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { ck_io24 }]; #IO_L8P_T1_AD14P_35	Sch=ad_p[14]	ChipKit pin=A10
#set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { ck_io25 }]; #IO_L8N_T1_AD14N_35	Sch=ad_n[14]	ChipKit pin=A11

## ChipKit SPI
#set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33 } [get_ports { ck_miso }]; #IO_L17N_T2_35 Sch=ck_miso
#set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { ck_mosi }]; #IO_L17P_T2_35 Sch=ck_mosi
#set_property -dict { PACKAGE_PIN F1    IOSTANDARD LVCMOS33 } [get_ports { ck_sck }]; #IO_L18P_T2_35 Sch=ck_sck
#set_property -dict { PACKAGE_PIN C1    IOSTANDARD LVCMOS33 } [get_ports { ck_ss }]; #IO_L16N_T2_35 Sch=ck_ss

## ChipKit I2C
#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { ck_scl }]; #IO_L4P_T0_D04_14 Sch=ck_scl
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { ck_sda }]; #IO_L4N_T0_D05_14 Sch=ck_sda
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { scl_pup }]; #IO_L9N_T1_DQS_AD3N_15 Sch=scl_pup
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33 } [get_ports { sda_pup }]; #IO_L9P_T1_DQS_AD3P_15 Sch=sda_pup

## Misc. ChipKit Ports
#set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { ck_ioa }]; #IO_L10N_T1_D15_14 Sch=ck_ioa
#set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { ck_rst }]; #IO_L16P_T2_35 Sch=ck_rst

## SMSC Ethernet PHY
#set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { eth_col }]; #IO_L16N_T2_A27_15 Sch=eth_col
#set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { eth_crs }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=eth_crs
#set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { eth_mdc }]; #IO_L14N_T2_SRCC_15 Sch=eth_mdc
#set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { eth_mdio }]; #IO_L17P_T2_A26_15 Sch=eth_mdio
#set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports { eth_ref_clk }]; #IO_L22P_T3_A17_15 Sch=eth_ref_clk
#set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { eth_rstn }]; #IO_L20P_T3_A20_15 Sch=eth_rstn
#set_property -dict { PACKAGE_PIN F15   IOSTANDARD LVCMOS33 } [get_ports { eth_rx_clk }]; #IO_L14P_T2_SRCC_15 Sch=eth_rx_clk
#set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { eth_rx_dv }]; #IO_L13N_T2_MRCC_15 Sch=eth_rx_dv
#set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[0] }]; #IO_L21N_T3_DQS_A18_15 Sch=eth_rxd[0]
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[1] }]; #IO_L16P_T2_A28_15 Sch=eth_rxd[1]
#set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[2] }]; #IO_L21P_T3_DQS_15 Sch=eth_rxd[2]
#set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[3] }]; #IO_L18N_T2_A23_15 Sch=eth_rxd[3]
#set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { eth_rxerr }]; #IO_L20N_T3_A19_15 Sch=eth_rxerr
#set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { eth_tx_clk }]; #IO_L13P_T2_MRCC_15 Sch=eth_tx_clk
#set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { eth_tx_en }]; #IO_L19N_T3_A21_VREF_15 Sch=eth_tx_en
#set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[0] }]; #IO_L15P_T2_DQS_15 Sch=eth_txd[0]
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[1] }]; #IO_L19P_T3_A22_15 Sch=eth_txd[1]
#set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[2] }]; #IO_L17N_T2_A25_15 Sch=eth_txd[2]
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[3] }]; #IO_L18P_T2_A24_15 Sch=eth_txd[3]

## Quad SPI Flash
#set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]

## Power Measurements
#set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33     } [get_ports { vsnsvu_n }]; #IO_L7N_T1_AD2N_15 Sch=ad_n[2]
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33     } [get_ports { vsnsvu_p }]; #IO_L7P_T1_AD2P_15 Sch=ad_p[2]
#set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33     } [get_ports { vsns5v0_n }]; #IO_L3N_T0_DQS_AD1N_15 Sch=ad_n[1]
#set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33     } [get_ports { vsns5v0_p }]; #IO_L3P_T0_DQS_AD1P_15 Sch=ad_p[1]
#set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33     } [get_ports { isns5v0_n }]; #IO_L5N_T0_AD9N_15 Sch=ad_n[9]
#set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33     } [get_ports { isns5v0_p }]; #IO_L5P_T0_AD9P_15 Sch=ad_p[9]
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33     } [get_ports { isns0v95_n }]; #IO_L8N_T1_AD10N_15 Sch=ad_n[10]
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33     } [get_ports { isns0v95_p }]; #IO_L8P_T1_AD10P_15 Sch=ad_p[10]

