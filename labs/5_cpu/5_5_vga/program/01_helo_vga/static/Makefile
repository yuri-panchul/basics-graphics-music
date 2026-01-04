LD=/opt/riscv_native/bin/riscv32-unknown-elf-gcc 
GCC=/opt/riscv_native/bin/riscv32-unknown-elf-gcc
OBJ = /opt/riscv_native/bin/riscv32-unknown-elf-objcopy
B2H = ../common/bin2hex
export objcopy := $(OBJ)
export bin2hex := $(B2H)

CFLAGS=  -I./barebones -I. -c -march=rv32i -mabi=ilp32 -g -ffreestanding -O0 -nostartfiles 
CIFLAGS=  -I./barebones -I. -c -march=rv32i -mabi=ilp32 -g -ffreestanding -O0 -nostartfiles 

LDFLAGS=-nostdlib -Tyrv.ld 

all:_divsi3.o _modsi3.o _mulsi3.o _udivmodsi4.o _udivsi3.o _umodsi3.o
	

_divsi3.o:_divsi3.c  
	$(GCC) $(CFLAGS) -o $@ $^

_modsi3.o:_modsi3.c  
	$(GCC) $(CFLAGS) -o $@ $^

_mulsi3.o:_mulsi3.c  
	$(GCC) $(CFLAGS) -o $@ $^

_udivmodsi4.o:_udivmodsi4.c  
	$(GCC) $(CFLAGS) -o $@ $^

_udivsi3.o:_udivsi3.c  
	$(GCC) $(CFLAGS) -o $@ $^

_umodsi3.o:_umodsi3.c
	$(GCC) $(CFLAGS) -o $@ $^

clean:
	rm -rf *.o *.a