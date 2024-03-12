Beginner's guide to Basics-graphics-music examples
==================================================

These are examples to demonstrate labs sessions for [systemverilog-homework](https://github.com/yuri-panchul/systemverilog-homework) which are portable [systemverilog](https://en.wikipedia.org/wiki/SystemVerilog)
examples for FPGA and ASIC.

[FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) Field Programmable Gate Array is a type of integrated circuit that can be programmed multiple times.
It consists of an array of programmable logic blocks and interconnects that can be configured to perform
various digital functions. FPGAs are commonly used in applications where flexibility, speed, and parallel
processing capabilities are required, such as in telecommunications, automotive and aerospace.

[ASIC](https://en.wikipedia.org/wiki/Application-specific_integrated_circuit), Application Specific Integrated Circuit, this is an integrated circuit chip designed for specific use
for instance, telecommunications, automotive etc.

These examples facilitate learning for beginners by:-

1. Removing EDA and FPGA vendor complexity and restrictions.
2. Compensating the gap between academia and industry in solving microarchitectural problems necessary for a career in ASIC design, building CPU, GPU and networking chips.
3. Reducing the barrier of entry for them or a person who is transitioning to FPGA/ASIC design.


Requirements:-

1. Ubuntu 23.10,supports latest icarus verilog 12, other versions of linux are supported also.
2. git.
3. FPGA board, the examples support 30 boards with FPGAs from Xilinx,Altera, Gowin and Lattice and
   aim to be compatible with open-source ASIC design tools.

A List of boards for various FPGA vendors:-

![List of boards](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/boards.png)


Step 1 download Intel Quartus
-----------------------------

[Go to](https://www.intel.com/content/www/us/en/software-kit/795187/intel-quartus-prime-lite-edition-design-software-version-23-1-for-linux.html)
and download Quartus Lite Edition 23.1. This version needs no license to generate files to program the FPGA

![download page](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/0.png)


Step 2 Running the installer
----------------------------

Right click on installer and select properties.

![Right click on installer and go to properties](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/1.png)

Set installer executable as program.

![Set installer executable as program](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm.png)

Sellect Devices depending on board you have check add on button, agree to licence and click download.

![GUI](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/2.png)

![download progress](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/3.png)

Installation Completed

![download done](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/5.png)

Step 3 Running Quartus
----------------------

Double click on desktop icon **OR** Navigate to installation directory in bin directory in command line and type

> ./quartus

![GUI](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/8.png)

Step 4 Installing git
---------------------

Open terminal and type

> sudo apt-get install git

Step 5 git clone Basic-graphics-music
------------------------------------

In terminal, at a desired location clone the main directory from github

> git clone https://github.com/yuri-panchul/basics-graphics-music

Step 6 Setup and Sellecting FPGA board.
-----------------------------
Connect your FPGA board via usb cable

![board connection](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/b0.jpg)

Open the cloned directory on your pc in terminal


![CLI](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm0.png) you can

> git pull

To update to the new version.

Run the bash script
> ./check_setup_and_choose_fpga_board.bash

Sellect the corresponding number of your boards DE10-lite is 16 and press ENTER The number might change depending
on cloned version of the directory. Some old boards that are not supported by Quartus 23.1 can be used by of the
software.

![Board sellection](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm0.png)

Choose N when prompted with choice to use Qurtus GUI The reason for N is because
you what to run one example after which you can try the rest.

![CLI choice](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm2.png)

Step 7 Running Shift register example
-------------------------------------

Navigate to shift register example by typing

> cd labs/08_shift_register

![08 shift register example location](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm3.png)

To Run synthesis in **CLI** run the script

> ./03_synthesize_for_fpga.bash

![Run synthesis script](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm4.png)

During synthesis a directory Run is generated, containing necessary files for programming the FPGA, after which the
programmer is run by the same script to program the board using the files. After a **successful!!** synthesis the response should be as bellow.

![success display](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/mm5.png)

Ensure all the LED switches are off All switches should be down because the left switch is used as a reset.

![board with switches off](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/b1.jpg)

The image bellow illustrates how a shift register works.

![register](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/register.png)

Press Reset button, KEY 0 to observe how logic 1 get shifted accross the registers If you use another board,
not DE10-Lite, reset might be allocated to another button.

![board after reset pressed](https://github.com/sisaphilip/myconfigs/blob/main/Pictures/b2.jpg)


You can run other scripts in the directory depending on what you want to do



Date 2024-02-06






