PCF = board_specific.pcf
DEVICE = 8k
PACKAGE = ct256
PROG_PARAM =

.PHONY: clean
all: $(NAME).bin 

.PHONY: upload
upload: $(NAME).bin
	iceprog $(PROG_PARAM) $(NAME).bin

fw: $(NAME).bin

$(NAME).bin: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(INC)" $(READ_VERILOG) -p "synth_ice40 -blif $(NAME).blif -top board_specific_top" -p "write_json $(NAME).json"
	nextpnr-ice40 --hx$(DEVICE) --package $(PACKAGE) --json $(NAME).json --pcf $(PCF) --pcf-allow-unconstrained --asc $(NAME).asc
	icepack -s $(NAME).asc $(NAME).bin

.PHONY: gui
gui: $(PCF) $(DEPS)
	yosys -p "verilog_defaults -add -I$(INC)" $(DEPS) -p "synth_ice40 -blif $(NAME).blif -top top" -p "write_json $(NAME).json" -p "hierarchy -check -top top" -p "proc" -p "show -prefix $(NAME) -notitle -colors 2 -width -format dot"
	netlistsvg -o $(NAME).svg $(NAME).json
	nextpnr-ice40 --hx$(DEVICE) --package $(PACKAGE) --json $(NAME).json --pcf $(PCF) --pcf-allow-unconstrained --asc $(NAME).asc --placed-svg $(NAME)-placed.svg --routed-svg $(NAME)-routed.svg 
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
	rm -f *.bin *.txt *.blif *.out *.svg *.dot *.vcd *~

