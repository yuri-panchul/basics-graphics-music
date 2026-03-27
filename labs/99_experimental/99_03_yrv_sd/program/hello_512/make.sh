#!/bin/bash
GCC=/c/opt/riscv/bin/riscv-none-elf-gcc
OBJ=/c/opt/riscv/bin/riscv-none-elf-objcopy

# Собираем объектный файл
$GCC -march=rv32i -mabi=ilp32 -nostdlib -c main.s -o main.o

# Линкуем, фиксируя начало на 0x0. 
# Это заставит .org 0x200 быть ровно на 512-м байте от начала.
$GCC -march=rv32i -mabi=ilp32 -nostdlib -Wl,-Ttext=0x0 main.o -o main.elf

# Создаем бинарник
$OBJ -O binary main.elf main.bin