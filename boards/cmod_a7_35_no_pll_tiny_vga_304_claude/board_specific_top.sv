// Board configuration cmod_a7_35_no_pll_tiny_vga_304_claude: the design of
// cmod_a7_35_tiny_vga_640_claude without the MMCM. The whole design runs on
// the 12 MHz oscillator, and a VGA line has 304 pixels. See README.md and
// the comment on top of the included file.

`define CMOD_A7_NO_PLL_SCREEN_WIDTH 304
`include "../cmod_a7_35_tiny_vga_640_claude/board_specific_top.sv"
