// Asynchronous reset here is needed for one of FPGA boards we use

`include "config.svh"

module flip_flop_fifo_empty_full_optimized_and_debug_2
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,
    input                push,
    input                pop,
    input  [width - 1:0] write_data,
    output [width - 1:0] read_data,
    output               empty,
    output               full,

    output [       31:0]              debug_ptrs,

    output [depth - 1:0]              debug_valid,
    output [depth - 1:0][width - 1:0] debug_data
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth),
               counter_width = $clog2 (depth + 1);

    localparam [counter_width - 1:0] max_ptr = counter_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr, rd_ptr;
    logic wr_ptr_odd_circle, rd_ptr_odd_circle;

    logic [width - 1:0] data [0: depth - 1];

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            wr_ptr <= '0;
            wr_ptr_odd_circle <= 1'b0;
        end
        else if (push)
        begin
            if (wr_ptr == max_ptr)
            begin
                wr_ptr <= '0;
                wr_ptr_odd_circle <= ~ wr_ptr_odd_circle;
            end
            else
            begin
                wr_ptr <= wr_ptr + 1'b1;
            end
        end

    //------------------------------------------------------------------------

    // TODO: Add logic for rd_ptr
    // START_SOLUTION

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            rd_ptr <= '0;
            rd_ptr_odd_circle <= 1'b0;
        end
        else if (pop)
        begin
            if (rd_ptr == max_ptr)
            begin
                rd_ptr <= '0;
                rd_ptr_odd_circle <= ~ rd_ptr_odd_circle;
            end
            else
            begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end

    // END_SOLUTION

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

    //------------------------------------------------------------------------

    wire equal_ptrs  = (wr_ptr == rd_ptr);
    wire same_circle = (wr_ptr_odd_circle == rd_ptr_odd_circle);

    assign empty = equal_ptrs & same_circle;

    // TODO: Add logic for full output
    // START_SOLUTION
    assign full = equal_ptrs & ~ same_circle;
    // END_SOLUTION

    //------------------------------------------------------------------------

    // TODO: Implement the debug signal generation
    // START_SOLUTION

    assign debug_ptrs [31:16] = 16' (wr_ptr);
    assign debug_ptrs [15:00] = 16' (rd_ptr);

    generate
        genvar i;

        for (i = 0; i < depth; i ++)
        begin : gen
            assign debug_data [i] = data [i];

            assign debug_valid [i]
                = same_circle
                    ? (i >= rd_ptr & i < wr_ptr)
                    : (i >= rd_ptr | i < wr_ptr | full);
        end
    endgenerate

    // END_SOLUTION

endmodule
