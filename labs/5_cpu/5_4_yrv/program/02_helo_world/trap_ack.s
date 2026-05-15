.section .text.trap_ack
.global trap_ack

           .equ  mie,    0x304
           .equ  mtvec,  0x305
           .equ  mcause, 0x342
           .equ  iobase, 0xffff0     # i/o at 0xffff0000

trap_ack:  csrr  t2, mcause
           blt   t2, x0, int_ack

           slli  t2, t2, 1           # discard msb
           li    t1, 0x16            # ecall
           bne   t1, t2, n_ecall

           li    t1, 0x20            # bit 12
           beq   zero, zero, set_led

n_ecall:   li    t1, 0x2             # bit 8
           beq   zero, zero, set_led

int_ack:   slli  t2, t2, 1           # discard msb
           li    t1, 0x16            # eint
           bne   t1, t2, n_eint

clr_int:   lui   a7, iobase          # i/o page
           lhu   t0, 6(a7)           # read port3
#           bseti t0, t0, 15
           sh    t0, 6(a7)           # write port3
#           bclri t0, t0, 15
           sh    t0, 6(a7)           # write port3
           mret

n_eint:    li    t1, 0x20            # li
           blt   t2, t1, n_li

           li    t1, 0x8             # bit 10
           beq   zero, zero, set_led

n_li:      li    t1, 0x4             # bit 9
           beq   zero, zero, set_led
