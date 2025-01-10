module ring_buffer_with_single_pointer_and_debug_1
# (
    parameter width = 256, depth = 10
)
(
    input                clk,
    input                rst,

    input                in_valid,
    input  [width - 1:0] in_data,

    output               out_valid,
    output [width - 1:0] out_data,

    output logic [depth - 1:0]              debug_valid,
    output logic [depth - 1:0][width - 1:0] debug_data
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ptr == max_ptr ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [depth - 1:0] valid;
    logic [width - 1:0] data [0: depth - 1];

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            valid <= '0;
        else
            valid [ptr] <= in_valid;

    always_ff @ (posedge clk)
        if (in_valid)
            data [ptr] <= in_data;

    assign out_valid = valid [ptr];
    assign out_data  = data  [ptr];

    //------------------------------------------------------------------------

    // TODO: Add logic to generate debug signals
    // START_SOLUTION

    always_comb
    begin
        for (int i = 0; i < depth; i ++)
        begin
            if (ptr >= i + 1)
            begin
                debug_valid [i] = valid [ptr - i - 1];
                debug_data  [i] = data  [ptr - i - 1];
            end
            else
            begin
                debug_valid [i] = valid [ptr + depth - i - 1];
                debug_data  [i] = data  [ptr + depth - i - 1];
            end
        end
    end

    // END_SOLUTION

endmodule
