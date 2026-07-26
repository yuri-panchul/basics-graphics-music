# RISC-V assembler program for simple demo of PicoRV soft-processor
.text

main:
    li      s0, 0x08000000      # Timer base address
    li      s1, 0x02000000      # LEDs base address
    li      s2, 1               # LED initial value
    li      s3, 0x10000         # LED overlap value
    li      t0, 10000000        # Timer incr value
    mv      t1, t0              # Comparison value

loop:                           # loop
    lw      t2, 0x0(s0)         # until timer value
    bltu    t2, t1, loop        # pass comparison value
    add     t1, t1, t0          # then increment comp value
    bgeu    t1, t0, int_handler # and update LED value
    mv      t1, t0              # reset comparison value if
                                # overflow
int_handler:
    sw      s2, 0x0(s1)         # set current value to LED
    slli    s2, s2, 1           # then update next value
    blt     s2, s3, done        # reset next value if
    li      s2, 1               # overlap
done:
    j       loop                # back to loop