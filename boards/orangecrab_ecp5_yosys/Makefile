PCF = board_specific.pcf
DEVICE = 25k
PACKAGE = CSFBGA285
FLASH_METHOD := $(shell cat flash_method 2> /dev/null)
FTDI_CHANNEL = 1

.PHONY: clean
all: $(NAME).bin

.PHONY: upload
dfu: $(NAME).dfu
	dfu-util -D $<

$(NAME).dfu : $(NAME).bin
	$(COPY) $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

upload: $(NAME).bin
ifeq ("$(FLASH_METHOD)", "flash")
	openFPGALoader -v --ftdi-channel $(FTDI_CHANNEL) -f --reset $(NAME).bin
else
	openFPGALoader -v --ftdi-channel $(FTDI_CHANNEL) --reset $(NAME).bin
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
	rm -f *.bin *.txt *.blif *.out *.svg *.dot *.dfu *out.config


