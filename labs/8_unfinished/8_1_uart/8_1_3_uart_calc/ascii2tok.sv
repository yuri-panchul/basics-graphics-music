module ascii2tok
    import uart_pkg::*;
# (
    parameter num_width = 16
) 
(
    input clk,
    input rst,

    output       fifo_pop_o,
    input [7:0]  fifo_data_i,
    input        fifo_empty_i,

    output                   tok_vld_o,    
    input                    tok_rdy_i,  
    output                   tok_is_num_o, 
    output [num_width - 1:0] tok_num_o, 
    output opcode_t          tok_op_o
);

    //------------------------------------------------------------------------

    localparam cr = 8'h0D;      // carriage return

    typedef enum bit [1:0] {
        IDLE   = 2'd0,
        IN_NUM = 2'd1,
        IN_OP  = 2'd2
    } lexer_state_t;
    lexer_state_t state, next_state; 

    //------------------------------------------------------------------------

    logic [num_width - 1:0] acc, next_acc;

    logic                   tok_is_num_r;
    logic [num_width - 1:0] tok_num_r;
    opcode_t                tok_op_r;
    logic                   tok_vld_r; 

    //------------------------------------------------------------------------

    logic    ch_is_digit;
    logic    ch_is_op;
    opcode_t ch_op;
 
    assign ch_is_digit = (fifo_data_i >= "0") & (fifo_data_i <= "9");
    assign ch_is_op    = (fifo_data_i == "+") | (fifo_data_i == "-") |
                         (fifo_data_i == "&") | (fifo_data_i == "|") |
                         (fifo_data_i == "^") | (fifo_data_i == "*") |
                         (fifo_data_i == cr)  | (fifo_data_i == "\n");
 
    always_comb begin
        case (fifo_data_i)
            "+":     ch_op = OP_ADD;
            "-":     ch_op = OP_SUB;
            "&":     ch_op = OP_AND;
            "|":     ch_op = OP_OR;
            "^":     ch_op = OP_XOR;
            "*":     ch_op = OP_MUL;
            cr, 
            "\n":    ch_op = OP_NL;   
            default: ch_op = OP_ADD;
        endcase
    end
 
    //------------------------------------------------------------------------

    always_comb begin  
        next_state = state; 
        next_acc   = acc; 

        case (state)
            IDLE: begin 
                if (~fifo_empty_i) begin 
                    if (ch_is_digit) begin 
                        next_state = IN_NUM;
                        next_acc   = num_width'(fifo_data_i - "0");
                    end 
                    else if (ch_is_op)
                        next_state = IN_OP; 
                end 
            end  

            IN_NUM: begin 
                if (tok_vld_o & tok_rdy_i) begin 
                    next_state = IDLE;
                    next_acc   = '0;
                end
                else if (~fifo_empty_i & ch_is_digit)
                    next_acc = (acc << 3) + (acc << 1) + num_width'(fifo_data_i - "0");
            end

            IN_OP: begin 
                if (tok_vld_o & tok_rdy_i)
                    next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            acc   <= '0;
        end 
        else begin
            state <= next_state;
            acc   <= next_acc;
        end
    end

    assign fifo_pop_o = (~fifo_empty_i & state == IDLE) | 
                        (~fifo_empty_i & state == IN_NUM & ch_is_digit);
 
    //------------------------------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            tok_vld_r <= 1'b0; 
        else if (tok_vld_o & tok_rdy_i)
            tok_vld_r <= 1'b0;
        else if (~fifo_empty_i & ((state == IDLE & ch_is_op) | (state == IN_NUM & ~ch_is_digit))) 
            tok_vld_r <= 1'b1; 
    end

    always_ff @(posedge clk) begin 
        if (state == IDLE & ~fifo_empty_i) begin 
            if (ch_is_op) begin
                tok_is_num_r <= 1'b0;
                tok_op_r     <= ch_op;
            end  
        end
        else if (state == IN_NUM & ~fifo_empty_i & ~ch_is_digit) begin 
            tok_is_num_r <= 1'b1; 
            tok_num_r <= acc;
        end
    end
 
    //------------------------------------------------------------------------

    assign tok_vld_o    = tok_vld_r;
    assign tok_is_num_o = tok_is_num_r;
    assign tok_num_o    = tok_num_r;
    assign tok_op_o     = tok_op_r;

endmodule