module start_pointer_request_generator
import linked_list_controller_configuration_and_types_package::*;
(
    input            clock,
    input            reset,

    output pointer_t start_pointer,
    output           start_pointer_valid,
    input            start_pointer_ready
);

    logic [3:0] n_request;

    always_ff @ (posedge clock)
        if (reset)
            n_request <= '0;
        else if (start_pointer_ready)
            n_request <= n_request + 4'd1;

    assign start_pointer_valid = (n_request != 4'd8);

    always_comb
        case (n_request)
        4'd0:    start_pointer = pointer_t' (7);
        4'd1:    start_pointer = pointer_t' (6);
        4'd2:    start_pointer = pointer_t' (2);
        4'd3:    start_pointer = pointer_t' (1);
        4'd4:    start_pointer = pointer_t' (0);
        default: start_pointer = pointer_t' (9);
        endcase

endmodule
