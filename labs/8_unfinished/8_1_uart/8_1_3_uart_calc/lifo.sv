module lifo
# (
    parameter width = 16,
    parameter depth = 16
) 
(
    input clk,
    input rst,

    input push,
    input pop,
    input pop2,

    input  [width - 1:0] wr_data,

    output [width - 1:0] tos,
    output [width - 1:0] nos,

    output empty,
    output full,

    output has_two
);

    localparam ptr_width = $clog2(depth + 1);

    logic [ptr_width - 1:0] ptr;

    logic [width - 1:0] data [0:depth - 1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            ptr <= '0;
        else begin
            case ({push, pop, pop2})
                3'b001:  ptr <= ptr - 2'd2; // pop2
                3'b010:  ptr <= ptr - 1'b1; // pop
                // 3'b011:  ptr <= ptr - 3'd3; // pop + pop2
                3'b100:  ptr <= ptr + 1'b1; // push
                3'b101:  ptr <= ptr - 1'b1; // push + pop2
                // 3'b111:  ptr <= ptr - 2'd2; // push + pop + pop2
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (push & pop2)
            data[ptr - 2] <= wr_data;
        else if (push)
            data[ptr] <= wr_data;
    end

    assign tos = data[ptr - 1];
    assign nos = data[ptr - 2];

    assign empty = (ptr == '0);  
    assign full  = (ptr == ptr_width'(depth));

    assign has_two = (ptr >= 2'd2);
    
endmodule
