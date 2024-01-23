module shift_register_with_valid_and_debug
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

    output [depth - 1:0]              debug_valid,
    output [depth - 1:0][width - 1:0] debug_data
);

    logic [depth - 1:0] valid;
    logic [width - 1:0] data [0: depth - 1];

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            valid <= '0;
        else
            valid <= { valid [$left (valid) - 1:0], in_valid };

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_valid = valid [depth - 1];
    assign out_data  = data  [depth - 1];

    //------------------------------------------------------------------------

    // TODO: Add logic to generate debug signals
    // START_SOLUTION

    assign debug_valid = valid;

    generate
        genvar i;

        for (i = 0; i < depth; i ++)
        begin : gen
            assign debug_data [i] = data [i];
        end
    endgenerate

    // END_SOLUTION

endmodule
