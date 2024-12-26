# Descriptions of command files

# Descriptions of command files

## 01_clean.bash

Cleans the run directory

## 02_simulate_rtl.bash

Calls the steps/02_simulate_rtl.source_bash file.
If the questa simulator is installed, questa is called, otherwise - icarus verilog and GTKWave

## 03_synthesize_for_fpga.bash

Calls the project build for the selected debug board and uploads the firmware to the board

## 04_configure_fpga.bash

Calls the firmware upload to the board.

## 05_run_gui_for_fpga_synthesis.bash

Calls the design system.

## 06_choose_another_fpga_board.bash

Selects the debug board.

## 07_synthesize_for_asic.bash

Building the project in the OpenLine system

## 08_visualize_asic_synthesis_results_1.bash

Displaying the build results.

## 09_visualize_asic_synthesis_results_2.bash

Displaying the build results.

## 10_simulate_rtl_icarus.bash

The icarus verilog simulation system is called without calling GTKWave.

## 11_simulate_rtl_gtkwave.bash

Calling GTKWave and the gtkwave.tcl command file

The gtkwave.tcl file specifies the signals to be displayed on the timing diagram.

## 12_prepare_step_1.bash

Copying files from the support/step_1 directory to the current project directory.

Files in the support/ directory are under version control.
*.sv files in the current project directory are not under version control.

## 13_run_serial_terminal.bash

Launching the program for working with the serial port
For Windows, the Putty program is launched. For Linux, the minicom program is launched. The programs must be configured to work with the serial port to which the debug board is connected.

* Setting up the Pytty program: [putty_setup.md](./putty_setup.md)
* Setting up the minicom program: [minicom_setup.md](./minicom_setup.md)