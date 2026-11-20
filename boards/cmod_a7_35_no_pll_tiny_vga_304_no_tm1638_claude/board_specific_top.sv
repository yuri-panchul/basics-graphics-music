// Board configuration cmod_a7_35_no_pll_tiny_vga_304_no_tm1638_claude:
// cmod_a7_35_no_pll_tiny_vga_304_claude without TM1638. The two buttons and the
// two LEDs of Cmod A7 are the keys and the LEDs of the labs, and there is no
// seven-segment display. See README.md.

`define CMOD_A7_NO_PLL_SCREEN_WIDTH 304
`define FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`include "../cmod_a7_35_tiny_vga_640_claude/board_specific_top.sv"
