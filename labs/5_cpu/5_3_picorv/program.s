# RISC-V assembler program for simple demo of PicoRV soft-processor

_start:
    li s0, 0x00000001       # Initial pattern: 0b0000...1 (LSB set)
    li s1, 0x3E8             # Target address (128)
    li s2, 0x100            # Maximal shifted value, depends from w_leds

main_loop:
    # Set up delay counter (adjusted for ~25M cycles)
    li t0, 0x1         # 12,500,000 iterations (0xBEBC20 = 12.5M)
    
delay_loop:
    addi t0, t0, -1         # Decrement counter
    bnez t0, delay_loop     # Loop until counter == 0
    
    # Store current pattern to address 128
    sw s0, 0(s1)
    
    # Shift pattern right by 1 bit
    slli s0, s0, 1
    
    # Reset pattern to  when it becomes 0
    bne s0, s2, main_loop       # Continue if pattern != 0
    li s0, 0x00000001           # Reset pattern
    j main_loop