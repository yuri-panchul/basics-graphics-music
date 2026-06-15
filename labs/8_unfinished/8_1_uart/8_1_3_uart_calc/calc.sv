module calc
    import uart_pkg::*;
# (
    parameter num_width = 16
) 
(
    input clk, 
    input rst,

    input                    tok_vld_i,
    output                   tok_rdy_o,
    input                    tok_is_num_i,
    input  [num_width - 1:0] tok_num_i,
    input  opcode_t          tok_op_i,
 
    output                   lifo_push_o,
    output                   lifo_pop_o,
    output                   lifo_pop2_o,
    output [num_width - 1:0] lifo_wr_data_o,
    input  [num_width - 1:0] lifo_tos_i,
    input  [num_width - 1:0] lifo_nos_i,
    input                    lifo_empty_i,
    input                    lifo_full_i,
    input                    lifo_has_two_i,
 
    output                   res_vld_o,
    output [num_width - 1:0] res_data_o
);

    //------------------------------------------------------------------------

    logic [num_width - 1:0] alu_res; 

    logic tok_accepted;

    logic                   res_vld_r;
    logic [num_width - 1:0] res_data_r;

    //------------------------------------------------------------------------

    always_comb begin
        case (tok_op_i)
            OP_ADD:  alu_res = lifo_nos_i + lifo_tos_i;
            OP_SUB:  alu_res = lifo_nos_i - lifo_tos_i;
            OP_AND:  alu_res = lifo_nos_i & lifo_tos_i;
            OP_OR:   alu_res = lifo_nos_i | lifo_tos_i;
            OP_XOR:  alu_res = lifo_nos_i ^ lifo_tos_i;
            OP_MUL:  alu_res = lifo_nos_i * lifo_tos_i;
            default: alu_res = '0;
        endcase
    end

    //------------------------------------------------------------------------

    assign tok_rdy_o    = ~lifo_full_i;
    assign tok_accepted = tok_vld_i & tok_rdy_o;

    assign lifo_push_o    = tok_accepted & (tok_is_num_i | (~tok_is_num_i &
                                           (tok_op_i != OP_NL) & lifo_has_two_i));
    assign lifo_wr_data_o = tok_is_num_i ? tok_num_i : alu_res;

    assign lifo_pop_o  = tok_accepted & ~lifo_empty_i & ~tok_is_num_i & (tok_op_i == OP_NL);
    assign lifo_pop2_o = tok_accepted & lifo_has_two_i & ~tok_is_num_i & (tok_op_i != OP_NL);

    //------------------------------------------------------------------------  

    always_ff @(posedge clk or posedge rst) begin 
        if (rst) 
            res_vld_r <= 1'b0; 
        else
            res_vld_r <= lifo_pop_o;
    end

    always_ff @(posedge clk) begin 
        if (lifo_pop_o)
            res_data_r <= lifo_tos_i;
    end 

    assign res_vld_o  = res_vld_r; 
    assign res_data_o = res_data_r;
    
endmodule