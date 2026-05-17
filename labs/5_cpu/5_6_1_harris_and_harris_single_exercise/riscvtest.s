# riscvtest.s
# Sarah.Harris@unlv.edu
# David_Harris@hmc.edu
# 27 Oct 2021
#
# Test the RISC-V processor.  
#  add, sub, and, or, slt, addi, lw, sw, beq, jal
# Added instructions: lui and xor (see *** in code below)
# If successful, it should write the value 0xABCDE7D5 to address 108

#       RISC-V Assembly         Description               Address   Machine Code
main:   addi x2, x0, 5          # x2 = 5                  0         00500113   
        addi x3, x0, 12         # x3 = 12                 4         00C00193
        addi x7, x3, -9         # x7 = (12 - 9) = 3       8         FF718393
        or   x4, x7, x2         # x4 = (3 OR 5) = 7       C         0023E233
        and  x5, x3, x4         # x5 = (12 AND 7) = 4     10        0041F2B3
        add  x5, x5, x4         # x5 = (4 + 7) = 11       14        004282B3
        beq  x5, x7, end        # shouldn't be taken      18        02728863
        slt  x4, x3, x4         # x4 = (12 < 7) = 0       1C        0041A233
        beq  x4, x0, around     # should be taken         20        00020463
        addi x5, x0, 0          # shouldn't happen        24        00000293
around: slt  x4, x7, x2         # x4 = (3 < 5)  = 1       28        0023A233
        add  x7, x4, x5         # x7 = (1 + 11) = 12      2C        005203B3
        sub  x7, x7, x2         # x7 = (12 - 5) = 7       30        402383B3
        sw   x7, 84(x3)         # [96] = 7                34        0471AA23 
        lw   x2, 96(x0)         # x2 = [96] = 7           38        06002103 
        add  x9, x2, x5         # x9 = (7 + 11) = 18      3C        005104B3
        lui  x4, 0xABCDE        # ***x4 = 0xABCDE000      40        ABCDE237
        addi x4, x4, 0x7CC      # ***x4 = 0xABCDE7CC      44        7CC20213
        jal  x3, end            # jump to end, x3 = 0x4C  48        008001EF
        addi x2, x0, 1          # shouldn't happen        4C        00100113
end:    add  x2, x2, x9         # x2 = (7 + 18)  = 25     50        00910133
        xor  x2, x2, x4         # ***x2 = 0xABCDE7D5      54        00414133
        sw   x2, 0x20(x3)       # mem[108] = 0xABCDE7D5   58        0221A023 
done:   beq  x2, x2, done       # infinite loop           5C        00210063
		
		