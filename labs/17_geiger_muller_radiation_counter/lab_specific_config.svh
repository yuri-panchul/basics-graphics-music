`ifndef LAB_SPECIFIC_CONFIG_SVH
`define LAB_SPECIFIC_CONFIG_SVH

// The following setting is needed for Gowin boards
   `define ENABLE_TM1638

// HCW-132 variant of LED & KEY TM1638 board controller
// `define HCW132

// `define EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

// `define DUPLICATE_TM_SIGNALS_WITH_REGULAR
// `define CONCAT_REGULAR_SIGNALS_AND_TM
   `define CONCAT_TM_SIGNALS_AND_REGULAR

`endif  // `ifndef LAB_SPECIFIC_CONFIG_SVH
