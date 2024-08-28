PCF = board_specific.pcf
DEVICE = 8k
PACKAGE = ct256
FLASH_METHOD := $(shell cat flash_method 2> /dev/null)

.PHONY: clean
all: $(NAME).bin

.PHONY: upload
upload: $(NAME).bin
	@echo "---------------------------------------------------"
	@echo " MPSSE / FTDI definitions"
	@echo "---------------------------------------------------"
	@echo " FTDI bank pinout typically used for iCE dev boards"
	@echo " BUS IO | Signal | Control"
	@echo " -------+--------+--------"
	@echo " xDBUS0 |    SCK | MPSSE  "
	@echo " xDBUS1 |   MOSI | MPSSE  "
	@echo " xDBUS2 |   MISO | MPSSE  "
	@echo " xDBUS3 |     nc |        "
	@echo " xDBUS4 |     CS | GPIO   "
	@echo " xDBUS5 |     nc |        "
	@echo " xDBUS6 |  CDONE | GPIO   "
	@echo " xDBUS7 | CRESET | GPIO   "
	@echo
ifeq ("$(FLASH_METHOD)", "flash")
	iceprog $(PROG_PARAM) $(NAME).bin
else
	iceprog -S $(PROG_PARAM) $(NAME).bin
endif

fw: $(NAME).bin

$(NAME).bin: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" $(READ_VERILOG) -p "synth_ice40 -noabc9 -blif $(NAME).blif -top board_specific_top" -p "write_json $(NAME).json"
	nextpnr-ice40 --hx$(DEVICE) --package $(PACKAGE) --json $(NAME).json --pcf $(PCF) --pcf-allow-unconstrained --asc $(NAME).asc
	icepack -s $(NAME).asc $(NAME).bin


.PHONY: gui
gui: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" $(READ_VERILOG) -p "read_verilog -sv +/ice40/cells_sim.v" -p "hierarchy -check -top board_specific_top" -p "proc; opt; fsm; memory; opt" -p "show -prefix $(NAME) -notitle -colors 2 -width -format dot"
	@if [ -f "`which dot`" ]; then \
		echo "Generating PDFs with schematics..."; \
		dot -Tpdf -O $(NAME).dot; \
	else \
		echo "Note: 'dot' utility is not installed, PDF won't be generated!"; \
	fi
	@echo "Generating SVGs with routing and placement..."
	netlistsvg -o $(NAME).svg $(NAME).json
	nextpnr-ice40 --hx$(DEVICE) --package $(PACKAGE) --json $(NAME).json --pcf $(PCF) --pcf-allow-unconstrained --asc $(NAME).asc --placed-svg $(NAME)-placed.svg --routed-svg $(NAME)-routed.svg
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
	rm -f *.bin *.txt *.blif *.out *.svg *.dot *.vcd *~


