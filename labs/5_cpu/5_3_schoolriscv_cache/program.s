# li pseudo-instruction

        li      t0, 0x2F          ## iterations count
        li      t2, 0x123         ## li is a pseudo command
        li      t3, 0x12345678    ## there li is two real instructions: lui and addi
        li      t4, 0x12345000    ## two real instructions: lui and addi
        li      t5, -0x123

# RISC-V fibonacci program
#
# Stanislav Zhelnio, 2020
# Amended by Yuri Panchul, 2024

init:

        li       t1, 0x1         ## iteration decrement value

        li       a1, 1
        li       a7, 0xffff0020  ## memory-mapped I/O: start/stop cycle counter port address
                                 ## RARS MMIO addresses is 0xffff0000 - 0xffffffe0
                                 ## two real instructions
        sw       a1, 0(a7)       ## cycle_cnt start

fibonacci:

        mv      a0, zero
        li      t2, 1

loop:   add     t3, a0, t2
        mv      a0, t2
        mv      t2, t3
        sub     t0, t0, t1
        bnez    t0, loop

        sw       zero, 0(a7)     ## cycle_cnt stop
        nop                      ## nop for program align; mem_ctrl prefetch take four commands time after time
finish: beqz     zero, finish

# RISC-V factorial program
# Uncomment it when necessary

#init:
#        li       t1, 0x1         ## iteration decrement value

#        li       a1, 1
#        li       a7, 0xffff0020  ## memory-mapped I/O: start/stop cycle counter port address
                                 ## RARS MMIO addresses is 0xffff0000 - 0xffffffe0
                                 ## two real instructions
#        sw       a1, 0(a7)       ## cycle_cnt start

#factorial:

#        li      a0, 1
#        li      t2, 2

#loop:   mul     a0, a0, t2       ## CPU support for the mul instruction required
#        addi    t2, t2, 1
#        sub     t0, t0, t1
#        bnez    t0, loop

#        sw       zero, 0(a7)     ## cycle_cnt stop
#        nop                      ## nop for program align; mem_ctrl prefetch take four commands time after time
#        nop
#        nop
#        nop
#finish: beqz     zero, finish
