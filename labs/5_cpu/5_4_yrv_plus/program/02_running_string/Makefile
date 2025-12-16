LD=/c/riscv/bin/riscv-none-elf-gcc 
GCC=/c/riscv/bin/riscv-none-elf-gcc
OBJ = /c/riscv/bin/riscv-none-elf-objcopy
B2H = ../common/bin2hex
export objcopy := $(OBJ)
export bin2hex := $(B2H)


B2H = ../common/bin2hex
export objcopy := $(OBJ)
export bin2hex := $(B2H)

CFLAGS=  -I./barebones -I. -c -march=rv32i_zbs_zicsr -mabi=ilp32  -ffreestanding -O0 
CIFLAGS=  -I./barebones -I. -c -march=rv32i_zbs_zicsr -mabi=ilp32 -ffreestanding -O0

LDFLAGS=-nostdlib -Tyrv.ld -march=rv32i -mabi=ilp32





LDFLAGS=-nostdlib -Tyrv.ld
 

all:code_demo.mem32
trap_ack.o:trap_ack.s
	$(GCC) $(CFLAGS) -o $@ $^

eset_led.o:eset_led.s
	$(GCC) $(CFLAGS) -o $@ $^

nmi_vec.o:nmi_vec.s
	$(GCC) $(CFLAGS) -o $@ $^

dbg_vec.o:dbg_vec.s
	$(GCC) $(CFLAGS) -o $@ $^

crt0.o:crt0.s
	$(GCC) $(CFLAGS) -o $@ $^

main.o:main.c
	$(GCC) $(CFLAGS) -o $@ $^

ee_printf.o:ee_printf.c
	$(GCC) $(CFLAGS) -o $@ $^

atoi.o:atoi.c
	$(GCC) $(CFLAGS) -o $@ $^
memset.o:memset.c
	$(GCC) $(CFLAGS) -o $@ $^



final.elf:crt0.o eset_led.o trap_ack.o nmi_vec.o dbg_vec.o main.o
	$(LD) $(LDFLAGS)  -o $@ $^  
#	$(LD) $(LDFLAGS)  -o $@ $^ static/_divsi3.o static/_modsi3.o static/_mulsi3.o static/_udivmodsi4.o static/_udivsi3.o static/_umodsi3.o 


final:final.elf
	$(OBJ) -O binary final.elf final

code_demo.mem32: final
	python ../common/freedom-bin2hex.py -w32  final > code_demo.mem32

clean:
	rm -rf *.o *.elf final code_demo.mem32