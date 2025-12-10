//
//  CDC-6600-style scoreboard
//  A minimalistic example aimed to demonstrate a computer architecture idea
//
//  Written in 2024 by Yuri Panchul
//  for the open-source projects:
//
//      systemverilog-homework
//      basic-graphics-music
//      Verilog Meetup
//      Digital Circuit Synthesis School
//

`ifdef UNDEFINED

`include "sc_defs.svh"

module sc_top
(
    input              clk,
    input              rst,

    input   ins_t      ins,
    input              ins_vld,
    output             ins_rdy,

    input   reg_idx_t  reg_idx,
    output  reg_dat_t  reg_dat
);

// Behavioral model


typedef struct
{
    logic     busy;
    logic     sub_op;  // To distinguish I_ADD and I_SUB

    reg_idx_t dst_reg;                 // H&P refers as Fi
    reg_idx_t src_reg_0;               // Fj
    reg_idx_t src_reg_1;               // Fk

    fu_id_t   fu_producing_src_reg_0;  // Qj
    fu_id_t   fu_producing_src_reg_1;  // Qk

    logic     fu_0_rdy;                // Rj
    logic     fu_1_rdy;                // Rk
}

typedef struct
{
    logic     result_pending;
    fu_id_t   fu;
}
reg_status_t;

ins_t   ins_to_issue;
fu_id_t fu_to_issue;

fu_status_t  [n_fus  - 1:0] fu_stats;
reg_status_t [n_regs - 1:0] reg_stats;

op_e op1, op2;

always_comb
begin
    issue        = 1'b0;
    ins_to_issue = 'x;

    op1 = ins_to_issue.op;
    if (op1 == I_SUB) op1 = I_ADD;

    for (int i = 0; i < n_fus; i ++)
    begin
        op2 = fu_stat [i].op;
        if (op2 == I_SUB) op2 = I_ADD;

        if (~ fu_stat [i].busy & op1 == op2)
        begin
            issue   = 1'b1;
            fu_id_t = i;
        end
    end
end

endmodule

`endif
