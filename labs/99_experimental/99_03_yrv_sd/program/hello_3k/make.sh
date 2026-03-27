#!/bin/bash

LD=/c/opt/riscv/bin/riscv-none-elf-gcc
GCC=/c/opt/riscv/bin/riscv-none-elf-gcc
OBJ=/c/opt/riscv/bin/riscv-none-elf-objcopy

$GCC -march=rv32i -mabi=ilp32 -nostdlib -c main.s -o main.o
$OBJ -O binary main.o main.bin