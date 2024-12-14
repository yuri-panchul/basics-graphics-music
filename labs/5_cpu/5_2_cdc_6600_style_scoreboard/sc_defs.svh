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

`ifndef SC_DEFS_SVH
`define SC_DEFS_SVH

localparam w_op      = 4,
           w_reg_idx = 4,
           w_reg_dat = 8,
           w_imm     = w_reg_dat,
           w_ins     = 16;

//----------------------------------------------------------------------------

typedef enum bit [w_op - 1:0]
{
    I_NOP  = 0,
    I_LI   = 1,  // Load Immediate
    I_ADD  = 2,
    I_SUB  = 3,
    I_MUL  = 4,
    I_DIV  = 5,
    I_SQRT = 6
}
op_e;

//----------------------------------------------------------------------------

typedef logic [w_reg_idx - 1:0] reg_idx_t;
typedef logic [w_reg_dat - 1:0] reg_dat_t;
typedef logic [w_imm     - 1:0] imm_t;
typedef logic [w_ins     - 1:0] ins_t;

//----------------------------------------------------------------------------

function [w_ins - 1:0] make_ins_nop ();
    return { I_NOP, { w_ins - w_op { 1'b0 } } };
endfunction

function [w_ins - 1:0] make_ins_ri (op_e op, reg_idx_t rd, imm_t imm);
    return { op, rd, imm };
endfunction

function [w_ins - 1:0] make_ins_rr (op_e op, reg_idx_t rd, rs);
    return { op, rd, rs, w_reg' (0) };
endfunction

function [w_ins - 1:0] make_ins_rr (op_e op, reg_idx_t rd, rs0, rs1);
    return { op, rd, rs0, rs1 };
endfunction

`endif  // `ifndef SC_DEF_SVH
