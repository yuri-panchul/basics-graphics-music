// Board configuration cmod_a7_35_no_tm1638:
// cmod_a7_35 without TM1638. The two buttons and the two LEDs of
// Cmod A7 are the keys and the LEDs of the labs, and there is no
// seven-segment display. See README.md.

`define FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`include "../cmod_a7_35/board_specific_top.sv"
