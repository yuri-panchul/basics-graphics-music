# RISC-V assembler program for simple demo of PicoRV soft-processor
.text

main:
    li s0, 0x00000001       # Initial pattern: 0b0000...1 (LSB set)
    li s1, 0x10010100       # Set target address
    li s2, 0x100            # Maximal shifted value, depends from w_leds
    li s3, 1                # Timer delay

    mv t0, s3               # Reset delay timer
    
delay_loop:
    addi t0, t0, -1         # Decrement counter
    bnez t0, delay_loop     # Loop until counter == 0

    sw s0, 0(s1)            # Store current pattern to address in s1
    slli s0, s0, 1          # Shift pattern right by 1 bit

    mv t0, s3               # Reset delay timer

    # Reset pattern if s0 == s2
    bne s0, s2, delay_loop  # Continue if pattern != 0
    li s0, 0x00000001       # Reset pattern
    j delay_loop
