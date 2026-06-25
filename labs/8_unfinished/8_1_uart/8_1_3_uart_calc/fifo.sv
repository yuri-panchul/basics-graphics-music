module fifo 
# (
    parameter width = 8,
    parameter depth = 16
) 
(
    input clk,
    input rst,

    input push,
    input pop,

    input  [width - 1:0] wr_data,
    output [width - 1:0] rd_data,

    output empty,
    output full
);

    localparam ptr_width = $clog2(depth);
    localparam max_ptr   = ptr_width'(depth - 1);

    logic [ptr_width - 1:0] wr_ptr, rd_ptr;

    logic wr_ptr_toggle, rd_ptr_toggle, ptr_equal;

    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;

            wr_ptr_toggle <= 1'b0;
            rd_ptr_toggle <= 1'b0;
        end
        else begin
            if (push) begin 
                if (wr_ptr == max_ptr) begin 
                    wr_ptr <= '0; 
                    wr_ptr_toggle <= ~wr_ptr_toggle;
                end 
                else 
                    wr_ptr <= wr_ptr + 1'b1;
            end
         
            if (pop) begin 
                if (rd_ptr == max_ptr) begin 
                    rd_ptr <= '0; 
                    rd_ptr_toggle <= ~rd_ptr_toggle;
                end 
                else  
                    rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (push)
            data[wr_ptr] <= wr_data;
    end

    assign rd_data = data[rd_ptr];

    assign ptr_equal = (wr_ptr == rd_ptr);

    assign empty = ptr_equal & wr_ptr_toggle == rd_ptr_toggle;
    assign full  = ptr_equal & wr_ptr_toggle != rd_ptr_toggle;
    
endmodule
