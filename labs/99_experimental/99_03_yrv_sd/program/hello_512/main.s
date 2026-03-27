.section .text
.globl _start

# Инициализация (Адрес 0x000)
_start:
    li s0, 0xFFFF0000    # port0
    li s1, 0xFFFF0002    # port1
    j letter_H

# --- СТРАНИЦА 1: 'H' ---
.org 0x200
letter_H:
    li t1, 0x00           
    sh t1, 0(s1)
    li t1, 0x8           
    sh t1, 0(s1)         
    .rept 10
    nop
    .endr
    li t2, 0x00    
    sh t2, 0(s0)
    li t2, 0b00110111    
    sh t2, 0(s0)
    .rept 100
    nop
    .endr
    j letter_E

# --- СТРАНИЦА 2: 'E' ---
.org 0x400
letter_E:
    li t1, 0x00           
    sh t1, 0(s1)
    li t1, 0x4           
    sh t1, 0(s1)
    .rept 10
    nop
    .endr
    li t2, 0x00    
    sh t2, 0(s0)
    li t2, 0b01001111    
    sh t2, 0(s0)
    .rept 100
    nop
    .endr
    j letter_L

# --- СТРАНИЦА 3: 'L' ---
.org 0x600
letter_L:
    li t1, 0x00           
    sh t1, 0(s1)
    li t1, 0x2           
    sh t1, 0(s1)
    .rept 10
    nop
    .endr
    li t2, 0x00    
    sh t2, 0(s0)
    li t2, 0b00001110    
    sh t2, 0(s0)
    .rept 100
    nop
    .endr
    j letter_O

# --- СТРАНИЦА 4: 'O' ---
.org 0x800
letter_O:
    li t1, 0x00           
    sh t1, 0(s1)
    li t1, 0x1           
    sh t1, 0(s1)
    .rept 10
    nop
    .endr
    li t2, 0x00    
    sh t2, 0(s0)
    li t2, 0b01111110    
    sh t2, 0(s0)
    .rept 100
    nop
    .endr
    j letter_H

# Обязательно пустая строка в конце файла!

