# BGM YRV-plus makefile
# Dmitry Petrenko 2025
#
# based on:
#	   Stanislav Zhelnio, 2017
#      microAptiv_UP makefile for MIPSfpga
#      Andrea Guerrieri scripts


#Put GCC path here
#
#
ifeq ($(OS),Windows_NT)
    # Windows detected
    GNU_MAKE_WINDOWS=true
else
    # Other systems like Linux/Mac
    GNU_MAKE_WINDOWS=false
endif

COM_PORT := 1

ifeq ($(OS),Windows_NT)
LD=/c/opt/riscv/bin/riscv-none-elf-gcc
GCC=/c/opt/riscv/bin/riscv-none-elf-gcc
OBJ = /c/opt/riscv/bin/riscv-none-elf-objcopy
else
LD=/home/verilog/install/gccrv/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-gcc
GCC=/home/verilog/install/gccrv/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-gcc
OBJ=/home/verilog/install/gccrv/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-objcopy
#LD=/opt/riscv/bin/riscv-none-elf-gcc
#GCC=/opt/riscv/bin/riscv-none-elf-gcc
#OBJ = /opt/riscv/bin/riscv-none-elf-objcopy
endif



B2H = ../common/bin2hex

.PHONY: check_python,uart


help:
	$(info make help        - show this message)
	$(info make check       - check that all tools installed)
	$(info make all         - bild program)
	$(info make final.elf   - build final.elf from sources)
	$(info make final       - make raw bianry from  final.elf)
	$(info make compile     - compile all C sources to ASM)
	$(info make disasm      - disassemble program.elf )
	$(info make clean       - delete all created files)
	$(info make uart        - load program into the device memory using UART loader)
	$(info make icarus      - simulate program and device using Icarus Verilog)
	$(info make gtkwave     - show the result of Icarus Verilog simulation in GTKWave)
	@echo
	@echo "Location of GCC compiler is: $(GCC)"
	@echo "Location of LD (linker) compiler is: $(LD)"
	@echo "Location of ObjCopy compiler is: $(OBJ)"
	@true


export objcopy := $(OBJ)
export bin2hex := $(B2H)


B2H = ../common/bin2hex
export objcopy := $(OBJ)
export bin2hex := $(B2H)

CFLAGS=  -I./barebones -I. -c -march=rv32i_zbs_zicsr -mabi=ilp32  -ffreestanding -O0 
CIFLAGS=  -I./barebones -I. -c -march=rv32i_zbs_zicsr -mabi=ilp32 -ffreestanding -O0
LDFLAGS=-nostdlib -Tyrv.ld
 

all:check code_demo.mem32
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

final:final.elf
	$(OBJ) -O binary final.elf final

code_demo.mem32: final
	python ../common/freedom-bin2hex.py -w32  final > code_demo.mem32

clean:
	rm -rf *.o *.elf final code_demo.mem32

PYTHON := $(python)

check_python:
	@python -V > /dev/null 2>&1 \
		&& { echo "Python is correctly installed."; } \
		|| { echo "Error: Python not installed or not accessible. Please install Python"; exit 1; }

check_ld:
	@$(LD) --version > /dev/null 2>&1 \
	&& { echo "$(LD) is correctly installed."; } \
		|| { echo "Error: Linker $(LD) not installed or not accessible."; \
			echo "Please install the RISC-V toolchain following instructions:"; \
			echo "- Download the pre-built toolchain from https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/tag/v15.2.0-1/"; \
			echo "- Extract it to your system directory (like '/c/riscv')"; \
			echo "- Ensure that '$(LD)' is available in PATH."; exit 1; }

check_gcc:
	@$(GCC) --version > /dev/null 2>&1 \
	&& { echo "$(GCC) is correctly installed."; } \
	|| { echo "Error: Compiler $(GCC) not installed or not accessible."; \
			echo "To fix this issue, follow these steps:"; \
			echo "- Install the RISC-V GCC toolchain from here: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/tag/v15.2.0-1/"; \
        	echo "- Add the toolchain's bin folder to your PATH environment variable."; exit 1; }

check_objcopy:
	@$(OBJ) --version > /dev/null 2>&1 \
		&& { echo "$(OBJ) is correctly installed."; } \
		|| { echo "Error: Object Copy Tool $(OBJ) not installed or not accessible."; \
			echo "Installation instructions:"; \
			echo "- Obtain the RISC-V objcopy binary as part of the RISC-V toolchain."; \
			echo "- Ensure that '$(OBJ)' is present in your PATH."; exit 1; }

check: check_ld check_gcc check_objcopy check_python



uart:
ifeq ($(OS),Windows_NT)
	$(eval cmd_str:=cmd.exe //C "mode COM$(COM_PORT) baud=115200 parity=n data=8 stop=1 to=off xon=off odsr=off octs=off dtr=off rts=off idsr=off || true")
	$(cmd_str)
	$(eval cmd_str:=cmd.exe //C "type code_demo.mem32 > \\.\COM$(COM_PORT)")
	$(cmd_str)
else
	USBDEV=/dev/ttyUSB0
	stty -F $(USBDEV) raw speed 115200 -crtscts cs8 -parenb -cstopb
	cat code_demo.mem32 > $(USBDEV)
endif
