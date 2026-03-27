.section .text
.globl _start

_start:
    # 10 пустых операций (NOP)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    # Безусловный переход на метку _start (к первому nop)
    j _start