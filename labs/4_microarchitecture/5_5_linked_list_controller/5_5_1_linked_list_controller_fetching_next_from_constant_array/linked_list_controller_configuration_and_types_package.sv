// sv_file_list.f lists this file first: a package has to be compiled
// before any file that imports it.

package linked_list_controller_configuration_and_types_package;

    localparam data_width    = 17,
               memory_depth  = 231,
               pointer_width = $clog2 (memory_depth);

    typedef logic [pointer_width - 1:0] pointer_t;
    typedef logic [data_width    - 1:0] data_t;

endpackage
