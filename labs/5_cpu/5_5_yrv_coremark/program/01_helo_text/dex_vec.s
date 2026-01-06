.section .text.dex_vec
.global dex_vec

           .equ  mie,    0x304
           .equ  mtvec,  0x305
           .equ  mcause, 0x342
           .equ  iobase, 0xffff0     # i/o at 0xffff0000

dex_vec:   li    t1, 0x50            # bits 13 and 11
           beq   zero, zero, dset_led
