`ifdef UNDEFINED

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

localparam w_op      = 4,                // Operation code width
           n_regs    = 16,               // Number of registers
           w_reg_idx = $clog2 (n_regs),  // Register index width
           w_reg_dat = 8,                // Register data width
           w_imm     = w_reg_dat,        // Immediate value width
           w_ins     = 16,               // Instruction width

           n_fus     = 16,               // Number of Functional Units
           w_fu_id   = $clog2 (n_fus);   // Functional Unit ID

//----------------------------------------------------------------------------

typedef enum bit [w_op - 1:0]
{
    I_LI   = 0,  // Load Immediate
    I_ADD  = 1,
    I_SUB  = 2,
    I_MUL  = 3,
    I_DIV  = 4,
    I_SQRT = 5
}
op_e;

//----------------------------------------------------------------------------

typedef logic [w_reg_idx - 1:0] reg_idx_t;
typedef logic [w_reg_dat - 1:0] reg_dat_t;
typedef logic [w_imm     - 1:0] imm_t;
typedef logic [w_ins     - 1:0] ins_t;
typedef logic [w_fu_id   - 1:0] fu_id_t;

//----------------------------------------------------------------------------

typedef struct
{
    logic     busy;
    op_e      op;

    reg_idx_t dst_reg;                 // H&P refers as Fi
    reg_idx_t src_reg_0;               // Fj
    reg_idx_t src_reg_1;               // Fk

    fu_id_t   fu_producing_src_reg_0;  // Qj
    fu_id_t   fu_producing_src_reg_1;  // Qk

    logic     fu_0_rdy;                // Rj
    logic     fu_1_rdy;                // Rk
}
fu_status_t;

//----------------------------------------------------------------------------

typedef struct
{
    logic     result_pending;
    fu_id_t   fu;
}
reg_status_t;

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

function [w_ins - 1:0] make_ins_rrr (op_e op, reg_idx_t rd, rs0, rs1);
    return { op, rd, rs0, rs1 };
endfunction

`endif  // `ifndef SC_DEF_SVH

`endif
