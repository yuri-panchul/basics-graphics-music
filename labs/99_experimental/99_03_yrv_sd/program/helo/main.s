.section .text
.globl _start

_start:
    # Инициализация адресов и констант
    li s0, 0xFFFF0000    # port0 (данные)
    li s1, 0xFFFF0002    # port1 (выбор разряда)
    
    # Регулируй s2 для яркости/мерцания. 
    # Начни с малого (например, 500), если моргает - увеличивай.
    li s2, 500           

main_loop:
    # --- Разряд 3: 'H' ---
    li t1, 0x8           
    li t2, 0b00110111    
    sh t1, 0(s1)
    sh t2, 0(s0)
    mv t0, s2
1:  addi t0, t0, -1
    bnez t0, 1b

    # --- Разряд 2: 'E' ---
    li t1, 0x4           
    li t2, 0b01001111    
    sh t1, 0(s1)
    sh t2, 0(s0)
    mv t0, s2
2:  addi t0, t0, -1
    bnez t0, 2b

    # --- Разряд 1: 'L' ---
    li t1, 0x2           
    li t2, 0b00001110    
    sh t1, 0(s1)
    sh t2, 0(s0)
    mv t0, s2
3:  addi t0, t0, -1
    bnez t0, 3b

    # --- Разряд 0: 'O' ---
    li t1, 0x1           
    li t2, 0b01111110    
    sh t1, 0(s1)
    sh t2, 0(s0)
    mv t0, s2
4:  addi t0, t0, -1
    bnez t0, 4b

    # Мгновенный переход к началу 'H'
    j main_loop