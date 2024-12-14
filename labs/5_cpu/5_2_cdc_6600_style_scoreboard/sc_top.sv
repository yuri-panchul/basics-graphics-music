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

endmodule
