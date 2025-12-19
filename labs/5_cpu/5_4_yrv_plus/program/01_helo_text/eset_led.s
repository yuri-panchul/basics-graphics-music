.section .text.eset_led
.global _start

           .equ  mie,    0x304
           .equ  mtvec,  0x305
           .equ  mcause, 0x342
           .equ  iobase, 0xffff0     # i/o at 0xffff0000

_start:
	   li    t1, 0x3f            # all leds on | load immediate  0011 1111

eset_led:  lui   a7, iobase          # i/o page Load Upper Immediate
           lhu   t0, 6(a7)           # a7 = iobase           
           slli  t1, t1, 7           # shift logical immediate 0001 1111 1000 0000
           or    t0, t0, t1          # set status led
           sh    t0, 6(a7) #a7 = iobase          # write port3
           beq   zero, zero, _run
