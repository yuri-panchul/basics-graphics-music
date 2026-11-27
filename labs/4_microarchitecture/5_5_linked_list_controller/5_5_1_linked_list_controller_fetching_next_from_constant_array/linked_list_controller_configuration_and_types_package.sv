// The guard lets lab_top.sv include this file. A package has to be
// compiled before any file that imports it, and the simulation script
// compiles the lab's files in alphabetical order, lab_top.sv first.

`ifndef LINKED_LIST_CONTROLLER_CONFIGURATION_AND_TYPES_PACKAGE_SV
`define LINKED_LIST_CONTROLLER_CONFIGURATION_AND_TYPES_PACKAGE_SV

package linked_list_controller_configuration_and_types_package;

    localparam data_width    = 17,
               memory_depth  = 231,
               pointer_width = $clog2 (memory_depth);

    typedef logic [pointer_width - 1:0] pointer_t;
    typedef logic [data_width    - 1:0] data_t;

endpackage

`endif
