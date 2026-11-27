package linked_list_controller_configuration_and_types_package;

    localparam data_width    = 17,
               memory_depth  = 231,
               pointer_width = $clog2 (memory_depth);

    typedef logic [pointer_width - 1:0] pointer_t;
    typedef logic [data_width    - 1:0] data_t;

endpackage

module linked_list_controller_1_fetching_next_from_constant_array
import linked_list_controller_configuration_and_types_package::*;
(
    input            clock,
    input            reset,

    input  pointer_t start_pointer,
    input            start_pointer_valid,
    output           start_pointer_ready,

    output logic     out_data_valid,
    output data_t    out_data
);

    `ifdef SYNOPSYS_CADENCE_MENTOR

    // This syntax probably works only with Synopsys VCS, Cadence Xselium
    // and QuestaSim from Siemens EDA (former Mentor Graphics)

    wire pointer_t [memory_depth - 1:0] next_pointers =
    '{
        1:  5,  5:  3,  3: 10, 10: 0,
        2:  4,  4:  0,
        6:  0,
        7: 15, 15:  8,  8:  0,
        9: 14, 14: 11, 11: 13, 13: 12, 12: 0,
        default: 0
    };

    wire data_t [memory_depth - 1:0] constant_data_array =
    '{
        1: "A",  5: "B",  3: "C", 10:   0,         // ABC
        2: "D",  4:   0,                           // D
        6:  0,                                     //
        7: "E", 15: "F",  8:   0,                  // EF
        9: "G", 14: "H", 11: "I", 13: "J", 12: 0,  // GHIJ
        default: 0
    };

    `else

    // Icarus Verilog (12, 13 and 14 devel) does not support keyed
    // assignment patterns like '{ 1: 5, default: 0 }, so for Icarus
    // the same two tables are filled by individual assignments.

    pointer_t [memory_depth - 1:0] next_pointers;

    always_comb
    begin
        next_pointers = '0;

        next_pointers [ 1] =  5;  // ABC
        next_pointers [ 5] =  3;
        next_pointers [ 3] = 10;
        next_pointers [10] =  0;

        next_pointers [ 2] =  4;  // D
        next_pointers [ 4] =  0;

        next_pointers [ 6] =  0;  // Empty

        next_pointers [ 7] = 15;  // EF
        next_pointers [15] =  8;
        next_pointers [ 8] =  0;

        next_pointers [ 9] = 14;  // GHIJ
        next_pointers [14] = 11;
        next_pointers [11] = 13;
        next_pointers [13] = 12;
        next_pointers [12] =  0;
    end

    data_t [memory_depth - 1:0] constant_data_array;

    always_comb
    begin
        constant_data_array = '0;

        constant_data_array [ 1] = "A";  // ABC
        constant_data_array [ 5] = "B";
        constant_data_array [ 3] = "C";
        constant_data_array [10] =  0;

        constant_data_array [ 2] = "D";  // D
        constant_data_array [ 4] =  0;

        constant_data_array [ 6] =  0;   // Empty

        constant_data_array [ 7] = "E";  // EF
        constant_data_array [15] = "F";
        constant_data_array [ 8] =  0;

        constant_data_array [ 9] = "G";  // GHIJ
        constant_data_array [14] = "H";
        constant_data_array [11] = "I";
        constant_data_array [13] = "J";
        constant_data_array [12] =  0;
    end

    `endif

    pointer_t current_pointer, next_pointer;
    logic next_pointer_valid;

    always_comb
    begin
        next_pointer = '0;

        if (out_data_valid)
            next_pointer = next_pointers [current_pointer];
        else if (start_pointer_valid)
            next_pointer = start_pointer;

        next_pointer_valid = (next_pointer != '0);
    end

    always_ff @ (posedge clock)
        if (reset)
            out_data_valid <= 1'b0;
        else
            out_data_valid <= next_pointer_valid;

    always_ff @ (posedge clock)
    begin
        current_pointer <= next_pointer;
        out_data        <= constant_data_array [next_pointer];
    end

    assign start_pointer_ready = ~ next_pointer_valid;

endmodule
