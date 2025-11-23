PCF = board_specific.pcf
DEVICE = up5k
PACKAGE = sg48
FLASH_METHOD := $(shell cat flash_method 2> /dev/null)

.PHONY: clean
all: $(NAME).bin

.PHONY: upload
upload:
	iceprog $(PROG_PARAM) $(NAME).bin

fw: $(NAME).bin

$(NAME).bin: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(subst :, -I,$(INC))" $(READ_VERILOG) -p "synth_ice40 -dsp -noabc9 -top board_specific_top -json $(NAME).json"
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --json $(NAME).json --pcf $(PCF) --asc $(NAME).asc
	icepack $(NAME).asc $(NAME).bin
	icetime -d $(DEVICE) -mt $(NAME).asc


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
	rm -f *.bin *.txt *.out *.svg *.dot *.vcd *~


