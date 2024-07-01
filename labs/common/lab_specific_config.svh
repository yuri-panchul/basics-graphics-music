`ifndef LAB_SPECIFIC_CONFIG_SVH
`define LAB_SPECIFIC_CONFIG_SVH

// This is the default file included
// when there is no lab_specific_config.svh
// in the lab directory

// The following setting is needed for Gowin boards
   `define ENABLE_TM1638

// HCW-132 variant of LED & KEY TM1638 board controller
// `define HCW132

// `define EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

   `define DUPLICATE_TM_SIGNALS_WITH_REGULAR
// `define CONCAT_REGULAR_SIGNALS_AND_TM
// `define CONCAT_TM_SIGNALS_AND_REGULAR


//Select one of
//`define VGA
//`define _480_272_LCD_RGB   // 4.3" display
`define _800_480_LCD_RGB   // 5.0", 7.0" display
//`define _1280_1024_LCD_RGB

`endif  // `ifndef LAB_SPECIFIC_CONFIG_SVH
