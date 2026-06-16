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
    localparam cnt_width = $clog2(depth + 1);

    logic [ptr_width - 1:0] wr_ptr, rd_ptr;
    logic [cnt_width - 1:0] cnt;

    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end
        else begin
            if (push)
                wr_ptr <= (wr_ptr == max_ptr) ? '0 : wr_ptr + 1'b1;
            if (pop)
                rd_ptr <= (rd_ptr == max_ptr) ? '0 : rd_ptr + 1'b1;
        end
    end

    always_ff @ (posedge clk) begin
        if (push)
            data[wr_ptr] <= wr_data;
    end

    assign rd_data = data[rd_ptr];

    always_ff @ (posedge clk or posedge rst) begin
        if (rst)
            cnt <= '0;
        else if (push & ~pop)
            cnt <= cnt + 1'b1;
        else if (pop & ~push)
            cnt <= cnt - 1'b1;
    end

    assign empty = (cnt == '0);  
    assign full  = (cnt == cnt_width'(depth));
    
endmodule
