CST = board_specific.cst
FREQ = 27
DEVICE_PART     := GW2A-LV18PG256C8/I7
DEVICE_PACK     := GW2A-18
DEVICE_FAMILY   := GW2A-18
#
FLASH_METHOD := $(shell cat flash_method 2> /dev/null)
UPLOAD_METHOD := $(shell cat upload_method 2> /dev/null)

.PHONY: clean
all: $(NAME).bin

.PHONY: upload
upload: $(NAME).bin
ifeq ("$(UPLOAD_METHOD)", "openloader")
	$(MAKE) upload_openloader
else
ifeq ("$(UPLOAD_METHOD)", "")
	echo "Upload method has not been chosen, use 'bash 04_configure_fpga.bash'"
else
	echo "Unsupported upload method: $(UPLOAD_METHOD), use 'bash 04_configure_fpga.bash'"
endif
endif

.PHONY: upload_openloader
upload_openloader:
ifeq ("$(FLASH_METHOD)", "flash")
	openFPGALoader -v -b tangprimer20k -f --reset --file-type fs $(NAME).bin
else
	openFPGALoader -v -b tangprimer20k --file-type fs $(NAME).bin
endif

fw: $(NAME).bin

$(NAME).bin: $(CST) $(DEPS)
	yosys -g -p "verilog_defaults -add -I$(INC)" $(READ_VERILOG) -p "synth_gowin -json $(NAME).json -top board_specific_top"
	nextpnr-gowin --enable-globals --freq $(FREQ) --device $(DEVICE_PART) --family $(DEVICE_FAMILY) --json $(NAME).json --write $(NAME).pack --cst $(CST)
	gowin_pack -d $(DEVICE_PACK) -o $@ $(NAME).pack

.PHONY: gui
gui: $(CST) $(DEPS)
	yosys -g -p "verilog_defaults -add -I$(INC)" $(READ_VERILOG) -p "synth_gowin -json $(NAME).json -top top" -p "hierarchy -check -top top" -p "proc" -p "show -prefix $(NAME) -notitle -colors 2 -width -format dot"
	netlistsvg -o $(NAME).svg $(NAME).json
	nextpnr-gowin --enable-globals --freq $(FREQ) --device $(DEVICE_PART) --family $(DEVICE_FAMILY) --json $(NAME).json --write $(NAME).pack --cst $(CST) --placed-svg $(NAME)-placed.svg --routed-svg $(NAME)-routed.svg
	@if [ -f "`which firefox`" ]; then \
		firefox $(NAME).svg $(NAME)-placed.svg $(NAME)-routed.svg; \
	else \
		echo "Firefox is not installed, cannot show you SVG files:"; \
		ls -al $(NAME).svg $(NAME)-placed.svg $(NAME)-routed.svg; \
	fi
	@if [ -f "`which xdot`" ]; then \
		xdot $(NAME).dot; \
	else \
		echo "xdot utility is not installed, cannot show you DOT file:"; \
		ls -al $(NAME).dot; \
	fi

.PHONY: sim
sim: $(NAME).v $(DEPS) $(NAME)_tb.v $(shell yosys-config --datdir)/ice40/cells_sim.v
	iverilog $^ -o $(NAME)_tb.out
	./$(NAME)_tb.out
	gtkwave $(NAME)_tb.vcd $(NAME)_tb.gtkw &


.PHONY: clean
clean:
	rm -f *.bin *.txt *.blif *.out *.svg *.dot *.dfu *out.config

