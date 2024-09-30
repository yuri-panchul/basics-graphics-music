LPF = board_specific.lpf
DEVICE = 25k
PACKAGE = CSFBGA285
FTDI_CHANNEL = 1 ### FT2232 has two channels, select 0 for channel A or 1 for channel B
#
FLASH_METHOD := $(shell cat flash_method 2> /dev/null)
UPLOAD_METHOD := $(shell cat upload_method 2> /dev/null)

.PHONY: clean
all: $(NAME).bin

.PHONY: upload
upload: $(NAME).bin
ifeq ("$(UPLOAD_METHOD)", "dfu")
	$(MAKE) upload_dfu
else
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
endif

.PHONY: upload_dfu
upload_dfu: $(NAME).dfu
	dfu-util -D $<

.PHONY: $(NAME).dfu
$(NAME).dfu: $(NAME).bin
	cp $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

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

$(NAME).bin: $(LPF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" $(READ_VERILOG) -p "synth_ecp5 -noabc9 -json $(NAME).json -top board_specific_top"
	nextpnr-ecp5 --package $(PACKAGE) --$(DEVICE) --json $(NAME).json --textcfg $(NAME)_out.config --lpf $(LPF) --lpf-allow-unconstrained
	ecppack --compress --freq 38.8 --input $(NAME)_out.config --bit $(NAME).bin


.PHONY: gui
gui: $(LPF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" $(READ_VERILOG) -p "read_verilog -sv +/ecp5/cells_bb.v" -p "hierarchy -check -top board_specific_top" -p "proc; opt; fsm; memory; opt" -p "show -prefix $(NAME) -notitle -colors 2 -width -format dot"
	@if [ -f "`which dot`" ]; then \
		echo "Generating PDFs with schematics..."; \
		dot -Tpdf -O $(NAME).dot; \
	else \
		echo "Note: 'dot' utility is not installed, PDF won't be generated!"; \
	fi
	@echo "Generating SVGs with routing and placement..."
	netlistsvg -o $(NAME).svg $(NAME).json
	nextpnr-ecp5 --package $(PACKAGE) --$(DEVICE) --json $(NAME).json --textcfg $(NAME)_out.config --lpf $(LPF) --lpf-allow-unconstrained --placed-svg $(NAME)-placed.svg --routed-svg $(NAME)-routed.svg
	@if [ -f "`which firefox`" ]; then \
		firefox $(NAME).svg $(NAME)-placed.svg $(NAME)-routed.svg $(NAME).*pdf; \
	else \
		echo "Firefox is not installed, cannot show you SVG and PDF files:"; \
		ls -al $(NAME).svg $(NAME)-placed.svg $(NAME)-routed.svg $(NAME).*pdf; \
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
	rm -f *.bin *.txt *.blif *.out *.svg *.dot *.dfu *.pdf *out.config


