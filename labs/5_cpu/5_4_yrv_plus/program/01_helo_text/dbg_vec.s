.section .text.dbg_vec
.global dbg_vec

           .equ  mie,    0x304
           .equ  mtvec,  0x305
           .equ  mcause, 0x342
           .equ  iobase, 0xffff0     # i/o at 0xffff0000

dbg_vec:  
           dret

