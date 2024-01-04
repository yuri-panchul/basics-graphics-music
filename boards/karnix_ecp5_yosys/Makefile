PCF = board_specific.pcf
DEVICE = 25k
PACKAGE = CABGA256
FTDI_CHANNEL = 0 ### FT2232 has two channels, select 0 for channel A or 1 for channel B
#
FLASH_METHOD := $(shell cat flash_method 2> /dev/null)
UPLOAD_METHOD := $(shell cat upload_method 2> /dev/null)

.PHONY: clean
all: $(NAME).bin

.PHONY: upload
upload: $(NAME).bin
ifeq ("$(UPLOAD_METHOD)", "ecpprog")
	$(MAKE) upload_ecpprog
else
ifeq ("$(UPLOAD_METHOD)", "openloader")
	$(MAKE) upload_openloader
else
ifeq ("$(UPLOAD_METHOD)", "")
	echo "Upload method has not been chosen, use 'bash 04_configure_fpga.bash'"
else
	echo "Unsupported upload method: $(UPLOAD_METHOD), use 'bash 04_configure_fpga.bash'"
endif
endif
endif

.PHONY: upload_openloader
upload_openloader:
ifeq ("$(FLASH_METHOD)", "flash")
	openFPGALoader -v --ftdi-channel $(FTDI_CHANNEL) -f --reset $(NAME).bin
else
	openFPGALoader -v --ftdi-channel $(FTDI_CHANNEL) $(NAME).bin
endif

.PHONY: upload_ecpprog
upload_ecpprog:
ifeq ("$(FLASH_METHOD)", "flash")
	ecpprog -I $(if $(filter $(FTDI_CHANNEL),0),A,B) -X $(NAME).bin
else
	ecpprog -I $(if $(filter $(FTDI_CHANNEL),0),A,B) -S $(NAME).bin
endif



fw: $(NAME).bin

$(NAME).bin: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(INC)" $(READ_VERILOG) -p "synth_ecp5 -json $(NAME).json -top board_specific_top"
	nextpnr-ecp5 --package $(PACKAGE) --$(DEVICE) --json $(NAME).json --textcfg $(NAME)_out.config --lpf $(PCF) --lpf-allow-unconstrained
	ecppack --compress --freq 38.8 --input $(NAME)_out.config --bit $(NAME).bin

.PHONY: gui
gui: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(INC)" $(READ_VERILOG) -p "synth_ecp5 -json $(NAME).json -top top" -p "hierarchy -check -top top" -p "proc" -p "show -prefix $(NAME) -notitle -colors 2 -width -format dot"
	netlistsvg -o $(NAME).svg $(NAME).json
	nextpnr-ecp5 --package $(PACKAGE) --$(DEVICE) --json $(NAME).json --textcfg $(NAME)_out.config --lpf $(PCF) --lpf-allow-unconstrained --placed-svg $(NAME)-placed.svg --routed-svg $(NAME)-routed.svg
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
	rm -f *.bin *.txt *.blif *.out *.svg *.dot *out.config

