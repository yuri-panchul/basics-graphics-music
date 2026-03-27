.section .text
.globl _start

_start:
    # 1. Смещение кода за пределы 512 байт (0x200)
    # 150 nop * 4 байта = 600 байт от начала файла.
    .rept 150
    nop
    .endr

    # Инициализация адресов (port0 - сегменты, port1 - разряды)
    li s0, 0xFFFF0000    
    li s1, 0xFFFF0002    

main_loop:
    # --- СИМВОЛ 'H' (Разряд 3) ---
    li t1, 0x8           
    sh t1, 0(s1)         # Выбрали разряд
    .rept 100            # Ждем, пока SPI прожует выбор разряда
    nop
    .endr
    li t2, 0b00110111    
    sh t2, 0(s0)         # Записали символ
    .rept 1000           # Основная пауза свечения (увеличь, если мерцает)
    nop
    .endr

    # --- СИМВОЛ 'E' (Разряд 2) ---
    li t1, 0x4           
    sh t1, 0(s1)
    .rept 100
    nop
    .endr
    li t2, 0b01001111    
    sh t2, 0(s0)
    .rept 1000
    nop
    .endr

    # --- СИМВОЛ 'L' (Разряд 1) ---
    li t1, 0x2           
    sh t1, 0(s1)
    .rept 100
    nop
    .endr
    li t2, 0b00001110    
    sh t2, 0(s0)
    .rept 1000
    nop
    .endr

    # --- СИМВОЛ 'O' (Разряд 0) ---
    li t1, 0x1           
    sh t1, 0(s1)
    .rept 100
    nop
    .endr
    li t2, 0b01111110    
    sh t2, 0(s0)
    .rept 1000
    nop
    .endr

    # Возврат в начало основного цикла
    j main_loop