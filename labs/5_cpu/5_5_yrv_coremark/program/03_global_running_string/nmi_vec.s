.section .text.nmi_vec
.global nmi_vec
.global set_led

           .equ  mie,    0x304
           .equ  mtvec,  0x305
           .equ  mcause, 0x342
           .equ  iobase, 0xffff0     # i/o at 0xffff0000

nmi_vec:   li    t1, 0x10            # bit 11

set_led:   lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
           slli  t1, t1, 7           # align bit set data
           or    t0, t0, t1          # set status led
           sh    t0, 6(a7)           # write port3
           beq   zero, zero, redo

