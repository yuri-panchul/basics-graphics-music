![The State of Caravel: the First Look](https://raw.githubusercontent.com/yuri-panchul/basics-graphics-music/refs/heads/main/misc/caravel/1_header.png)

# The State of Caravel: the First Look
Yuri Panchul, 2025.1.15

This text is a mix of my thoughts on using Caravel and Open Lane together with a report on my first attempt to do the following:

1. Setup on 5 platforms: three Linux distributions, Windows and MacOS.
2. Running RTL-to-GDSII flow for eFabless examples.
3. Running RTL and gate-level simulation for eFabless examples.
4. Working with chipIgnite demo / evaluation / development board.

Let's start by defining a specific area where Caravel can be useful.

## 1. Caravel as a tool to train balancing microarchitecture, area and timing

Before joining an electronic company, a student who aims to become an RTL engineer - should be trained in developing pipelined designs. Not just a traditional 5-stage pipelined CPU, but pipelined data processing used in networking chips, GPUs and ML accelerators.

Such training requires doing a lot of exercises using a Verilog simulator to learn the tricks of maximizing bandwidth. However, learning microarchitecture without developing intuition about static timing analysis does not make sense: the students have to synthesize their designs to make sure the pipeline does not break the timing.

This is usually done in FPGA labs, however FPGA timing and utilization are different from ASICs, so here is another option: using eFabless Caravel infrastructure on the top of the Open Lane ASIC RTL-to-GDSII toolchain.

## 2. The Usage Scenario

The presumed usage scenario is:

1. We get a group of students who do Verilog simulation exercises using systemverilog-homework exercises and FPGA labs using basics-graphics-music (BGM) repository.

2. At some point, the students create their own designs using the BGM framework that isolates the students from FPGA vendor-specific details. Once a student’s design works on an FPGA board, the student can transfer his board-independent modules into a modified Caravel infrastructure.

3. The group can pack 15-30 designs into one Caravel or Caravel-Mini, depending on the required area and the costs. Glue logic, together with a housekeeping RISC-V core, can activate only one design at a time.

4. Alternatively, instead of making individual designs, the student team can work on a larger project, such as a mid-range CPU core with caches and MMU. In this way, the students can learn how to cooperate in a setting similar to an industrial team.

5. While working on a Caravel-based project, a student may re-engineer his pipelines to meet area and timing budgets. Eventually, the whole group will do a tapeout and get their chip manufactured in a few months.

## 3. The Alternatives

The alternative to Open Lane is to use Synopsys or Cadence licenses, but they are not available to everybody.

The alternative to the Caravel harness is to use TinyTapeout. While Tiny Tapeout is web-based and is easier from the installation point of view, it offers less area and fewer GPIO pins for each project. TinyTapeout also does not have an easy option to connect the design to a RISC-V housekeeping core available in Caravel. Cost-wise, TinyTapeout is more affordable for an individual student: $50 per tile of ~1000 ASIC standard cells, up to 16 tiles per project, plus a $200 development board. However, TinyTapeout infrastructure does not allow a group of students to build a larger project.

## 4. The Evaluation

Let's evaluate how robust the combination of Caravel and Open Lane is to start such training.

### 4.1. Step 1. The capacity estimation

Caravel-Mini is four times smaller than full Caravel and is less expensive, $3.5K versus $10K. Since Tiny Tapeout uses Caravel Infrastructure and has 512 tiles, we can roughly estimate that full Caravel accommodates ~512K standard cells and Caravel-Mini accommodates ~128K standard cells. This makes Caravel ~2.5 times more cost-efficient area-wise than TinyTapeout, and Caravel-Mini ~1.8 times more cost-efficient area-wise than TinyTapeout. Which is expected, this is similar to the difference in wholesale versus retail.

Based on a rough estimation of 1:10 D-flip-flop and logic gates ratio in a typical ASIC design and a knowledge of industrial MIPS CPU cores in the past, we can guess that Caravel can accommodate a mid-range industrial CPU core such as MIPS 24K used in WiFi routers and capable of running Linux. Caravel-Mini can probably accommodate only microcontroller cores such as various MIPS 4K or Cortex M derivatives and their RISC-V equivalents. TinyTapeout, with its limits up to 16 tiles or ~16K standard cells, can be used only for simplified educational CPU cores such as schoolRISCV.

### 4.2. Step 2. Generating the baseline projects from the templates

This step is straightforward. I generated two GitHub repos from eFabless templates: 

* https://github.com/yuri-panchul/caravel_user_mini_experiment is generated from https://github.com/efabless/caravel_user_mini

* https://github.com/yuri-panchul/caravel_user_project_experiment is generated https://github.com/efabless/caravel_user_project

This happened on December 23, 2024 using the latest version.

### 4.3. Step 3. Setup

I did the setup on 5 platforms: Ubuntu 24.04 LTS, Lubuntu 24.04 LTS, Simply Linux 10.4, Windows 11 with WSL (Windows Subsystem Linux) Ubuntu and MacOS on Apple Silicon (Mac Mini 4).

#### 4.3.1. Setup on Ubuntu 24.04 LTS

First, three dependencies were missing: make, python3-pip and docker. I installed the first two using apt-get and docker using the instruction from https://docs.docker.com/engine/install/ubuntu .
However it was not sufficient; I also had to use systemctl and gpasswd commands. Finally, I had to install a Python virtual environment using “sudo apt install python3.12-venv”. After this, “make setup” worked.

See *Appendix A.1. Ubuntu setup commands* for more details.

#### 4.3.2. Setup on Lubuntu 24.04 LTS

Setup on Lubuntu was similar to Ubuntu, I don't remember the difference, but maybe there were less bumps. See *Appendix A.2. Commands used to setup under Lubuntu 24.04 LTS* for more details.

#### 4.3.3. Setup on Simply Linux 10.4

Setup on Simply Linux did not ask for Docker or virtual environments, but this was probably due to the fact that I already had Open Lane up and running on my Simply Linux installation which was prepared by Anton Midyukov, a maintainer of Simply Linux distribution.

On one of Simply Linux systems I had to install *pyyaml*:

```bash
sudo apt-get install pip
python3 -m pip install pyyaml
```

#### 4.3.4. Setup on MacOS Sequoia 15.2, Apple Silicon, Mac Mini 4

This setup was relatively smooth: I had to install Docker following internet instructions for Docker for Mac, clone repositories and run ‘make setup’. The only bump was I had to install Python’s click package in a virtual environment:

```bash
cd ~/projects
git clone https://github.com/yuri-panchul/caravel_user_mini_experiment
cd caravel_user_mini_experiment
make setup
# Failure

source venv/bin/activate
python3 -m pip install click
make setup

# Success
```

#### 4.3.5. Setup on Windows 11 with WSL (Windows Subsystem Linux) Ubuntu

Similarly to MacOS, I had to install Docker following internet instructions for Docker for Windows, then install a specific version of Python and Python’s click package in a virtual environment:

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install docker-ce
sudo apt install python3.10-venv
sudo apt install python3-pip
pip install click
```

Unlike stand-alone Ubuntu and MacOS, WSL Ubuntu under Windows 11 does not require to activate the virtual environment explicitly, at least I don't see such activation in my log. This is a strange inconsistency.

#### 4.3.6. The setup bottom line

It is still unclear to me why Open Lane and Caravel need Docker. All this software is just a set of file-to-file conversion programs, albeit sophisticated. They don’t use networking, drivers for exotic devices or some special services from the operating system. Xilinx Vivado, Altera Quartus, Gowin IDE - none of this software needs Docker. For me, Docker is just an additional hassle when installing a system of this kind.

First, I thought Docker was needed to fix the Python versioning. I am aware that Python has chaos in versioning so I do understand the need for Python virtual environments. But what is the need to have both Docker and Python virtual environments?

In any case, as we can see, even Docker does not save from installation bumps like “click” package here and there.

### 4.4. Step 4. Running RTL-to-GDSII flow for the included example

#### 4.4.1. Running RTL-to-GDSII flow for the example included in Caravel-Mini

```bash
make user_project_wrapper_mini
```

This command was successfully completed on all platforms: Ubuntu, Lubuntu, Simply, MacOS and Windows WSL.

It generated a GDSII file together with the reports, which are sufficient to train the students in tuning their microarchitecture against the area and timing budgets:

1. **1-synthesis.AREA_0.stat.rpt** - area report.
2. **33-rcx_sta.summary.rpt** - slack and other Static Timing Analysis (STA) summary.
3. **33-rcx_sta.max.rpt** - timing path details / setup.
4. **33-rcx_sta.min.rpt** - timing path details / hold.
5. **33-rcx_sta.power.rpt** - power estimation (not sure how it estimates switching power though).

However, I found that STA reports on different platforms differ. While this difference may not be significant or might be caused by some Open Lane checkin between the installations, it should be investigated. It might be an artifact of some Python or C sort function or a real bug, but whatever it is, it would be better from the user's perspective to make the results on all platforms identical.

Specifically, *33-rcx_sta.max.rpt* and *33-rcx_sta.min.rpt* reports generated on MacOS differ from the same reports generated on Lubuntu:

![tkdiff STA reports for Caravel-Mini between Lubuntu and MacOS](https://raw.githubusercontent.com/yuri-panchul/basics-graphics-music/refs/heads/main/misc/caravel/2_tkdiff_hold_sta.png)

#### 4.4.2. Running RTL-to-GDSII flow for the example included in regular (not Mini) Caravel

```bash
make user_project_wrapper
```

This command was completed successfully on the first try on Ubuntu, MacOS and Windows WSL. However I was not able to find the area report, which is a critical issue.

Two runs on Lubuntu were not successful, but this was probably due to external factors:

1. Run low on disk space - see for details *Appendix C.1. Log for unsuccessful run 'make user_project_wrapper' under Lubuntu LTS 24.04*. It was not clear from the error message that the disk space is an issue.

2. Run low on memory - the command hangs on a computer with 4 gigabytes of RAM after step 25.

The third try, on a computer with 8 GB of memory, was successful. This means that Open Lane / Caravel infrastructure cannot gracefully detect and report insufficient resource conditions with a meaningful error message.

Run on Simply Linux 10.4 failed - see for details *Appendix C.2. Log 1 for an unsuccessful run 'make user_project_wrapper' under Simply Linux 10.4*, and *Appendix C.3. Log 2 for an unsuccessful run 'make user_project_wrapper' under Simply Linux 10.4*.

### 4.5. Step 5. Verification

#### 4.5.1. Caravel and cocotb

I did not dig into the details of Caravel verification, but it generally relies on cocotb, a Python-based solution that tries to mimic SystemVerilog (randomization, coverage) and UVM (an OOP library to structure a testbench) using Python.

While cocotb has an enthusiastic community of fans, I don't see it widely accepted in the electronic industry. I don't see electronic companies posting jobs with cocotb as a requirement, and I suspect the regression run time with cocotb might be too high for large projects. We already suffer in the industry with overnight regressions, but multiple day regressions might be too much. For this reason, I avoid using cocotb in education and keep SystemVerilog as the primary vehicle for verification as much as possible for free tools.

Icarus does not support randomization and coverage, but it does support fork, queues with $, and other SystemVerilog features that are sufficient to build reasonably sophisticated self-checking testbenches. So my approach with both Tiny Tapeout and Caravel would be to bypass cocotb: use it to drive the clock, start SystemVerilog actions and wait until SV is done. I prefer to drive the stimuli and do all the scoreboarding in SystemVerilog.

#### 4.5.2. Caravel and RISC-V

Tiny Tapeout uses MicroPython to control the user's design. Caravel has a housekeeping RISC-V core which a user can program in C. I did not dig deeper in Caravel verification but it looks like Caravel testbench allows to co-simulate software running on this core together with the user's Verilog design. I guess the same code can be used to control the design on chipIgnite demo board. If this is true, then Caravel allows a very useful form of teaching system design and software/hardware co-sumulation to the students. It can be added not only to the hardware design classes but also to embedded programming courses.

See for example the C code for a basic counter test `caravel_mini/verilog/dv/cocotb/counter_tests/counter_la/counter_la.c`:

```C
#include <common.h>
#include "../common/common.h"

void main(){
    // Enable managment gpio as output to use as indicator for finishing configuration
    mgmt_gpio_o_enable();
    mgmt_gpio_wr(0);
    enable_hk_spi(0); // disable housekeeping spi
    // configure all gpios as  user out then chenge gpios from 32 to 37 before loading this configurations
    configure_all_gpios(GPIO_MODE_USER_STD_OUT_MONITORED);
    configure_gpio(36, GPIO_MODE_MGMT_STD_INPUT_PULLDOWN);
    configure_gpio(37, GPIO_MODE_MGMT_STD_INPUT_PULLDOWN);
    gpio_config_load(); // load the configuration
    enable_user_interface();

    mgmt_gpio_wr(1); // configuration finished

    set_la_reg(0,7);
    set_la_oen(0,0xC0000000);
    set_la_oen(0,0xFFFFFFFF);

    return;
}
```

Now we have an issue with Simply Linux 10.4 which has a package for 64-bit RISC-V toolchain but does not have the 32-bit RISC-V toolchain package. In principle, I could build a 32-bit RISC-V toolchain from the source, but this would be a hassle.

#### 4.5.3. Verification results




## Appendix A.1. Ubuntu setup commands

```bash
sudo apt install make git
sudo apt-get install python3-pip -y

# Using instruction from https://docs.docker.com/engine/install/ubuntu/

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:

echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

# end of https://docs.docker.com/engine/install/ubuntu/

sudo systemctl start docker
sudo systemctl enable docker
sudo gpasswd -a $USER docker

sudo apt install python3.12-venv

cd ~/projects
git clone https://github.com/yuri-panchul/caravel_user_mini_experiment
cd caravel_user_mini_experiment
make setup
```

## Appendix A.2. Commands used to setup under Lubuntu 24.04 LTS

```bash
sudo apt install git
git clone https://github.com/yuri-panchul/caravel_user_mini_experiment.git
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo apt-get upgrade
sudo apt install -y build-essential python3 python3-venv python3-pip make git
sudo apt-get install docker.io

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world

sudo groupadd docker
sudo usermod -aG docker $USER

sudo reboot # REBOOT!

docker run hello-world

# ...
cd ~/projects
git clone https://github.com/yuri-panchul/caravel_user_mini_experiment
cd caravel_user_mini_experiment
make setup
```

## Appendix B.1. Caravel-Mini area report: **1-synthesis.AREA_0.stat.rpt**

```
62. Printing statistics.

=== user_project_wrapper_mini4 ===

   Number of wires:                359
   Number of wire bits:            655
   Number of public wires:          19
   Number of public wire bits:     315
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                481
     sky130_fd_sc_hd__a211o_2        6
     sky130_fd_sc_hd__a21o_2        11
     sky130_fd_sc_hd__a21oi_2       24
     sky130_fd_sc_hd__a221oi_2       1
     sky130_fd_sc_hd__a22o_2         2
     sky130_fd_sc_hd__a22oi_2        3
     sky130_fd_sc_hd__a2bb2o_2       1
     sky130_fd_sc_hd__a31o_2        36
     sky130_fd_sc_hd__a31oi_2        1
     sky130_fd_sc_hd__a32o_2         2
     sky130_fd_sc_hd__a41o_2        10
     sky130_fd_sc_hd__and2_2        12
     sky130_fd_sc_hd__and2b_2        2
     sky130_fd_sc_hd__and3_2        13
     sky130_fd_sc_hd__and3b_2       25
     sky130_fd_sc_hd__and4_2        17
     sky130_fd_sc_hd__buf_2         29
     sky130_fd_sc_hd__conb_1        49
     sky130_fd_sc_hd__dfxtp_2       61
     sky130_fd_sc_hd__inv_2          5
     sky130_fd_sc_hd__mux2_1        32
     sky130_fd_sc_hd__nand2_2       19
     sky130_fd_sc_hd__nand2b_2       1
     sky130_fd_sc_hd__nand4_2        3
     sky130_fd_sc_hd__nor2_2        27
     sky130_fd_sc_hd__o211a_2        8
     sky130_fd_sc_hd__o211ai_2       1
     sky130_fd_sc_hd__o21a_2         9
     sky130_fd_sc_hd__o21ai_2       27
     sky130_fd_sc_hd__o21ba_2        2
     sky130_fd_sc_hd__o2bb2a_2      14
     sky130_fd_sc_hd__o31ai_2        1
     sky130_fd_sc_hd__or2_2          3
     sky130_fd_sc_hd__or3_2          3
     sky130_fd_sc_hd__or3b_2         3
     sky130_fd_sc_hd__or4b_2        15
     sky130_fd_sc_hd__xor2_2         3

   Chip area for module '\user_project_wrapper_mini4': 4743.299200
```

## Appendix B.2. **33-rcx_sta.summary.rpt** static timing analysis summary

```
===========================================================================
report_tns
============================================================================
tns 0.00

===========================================================================
report_wns
============================================================================
wns 0.00

===========================================================================
report_worst_slack -max (Setup)
============================================================================
worst slack 8.95

===========================================================================
report_worst_slack -min (Hold)
============================================================================
worst slack 1.96
```

## Appendix B.3. A fragment of **33-rcx_sta.max.rpt** report: critical path / setup

```
===========================================================================
report_checks -path_delay max (Setup)
============================================================================
======================= Typical Corner ===================================

Startpoint: la_oenb[12] (input port clocked by clk)
Endpoint: _716_ (rising edge-triggered flip-flop clocked by clk)
Path Group: clk
Path Type: max

Fanout     Cap    Slew   Delay    Time   Description
-----------------------------------------------------------------------------
                          0.00    0.00   clock clk (rise edge)
                          6.00    6.00   clock network delay (propagated)
                         10.00   16.00 v input external delay
                  0.44    0.00   16.00 v la_oenb[12] (in)
     1    0.00                           la_oenb[12] (net)
                  0.44    0.00   16.00 v hold708/A (sky130_fd_sc_hd__dlygate4sd3_1)
                  0.06    0.76   16.76 v hold708/X (sky130_fd_sc_hd__dlygate4sd3_1)
     1    0.00                           net1020 (net)
                  0.06    0.00   16.76 v input36/A (sky130_fd_sc_hd__clkbuf_8)
                  0.08    0.19   16.96 v input36/X (sky130_fd_sc_hd__clkbuf_8)
     2    0.06                           net36 (net)
                  0.08    0.01   16.97 v hold709/A (sky130_fd_sc_hd__dlygate4sd3_1)
                  0.41    0.92   17.89 v hold709/X (sky130_fd_sc_hd__dlygate4sd3_1)
     4    0.08                           net1021 (net)
                  0.41    0.02   17.91 v _389_/B (sky130_fd_sc_hd__and4_1)
                  0.13    0.45   18.36 v _389_/X (sky130_fd_sc_hd__and4_1)
     2    0.03                           _077_ (net)
                  0.13    0.00   18.36 v _391_/C (sky130_fd_sc_hd__and4_1)
                  0.06    0.26   18.62 v _391_/X (sky130_fd_sc_hd__and4_1)
     2    0.01                           _079_ (net)
                  0.06    0.00   18.62 v _393_/A2 (sky130_fd_sc_hd__a21o_2)
                  0.11    0.30   18.93 v _393_/X (sky130_fd_sc_hd__a21o_2)
     4    0.03                           _081_ (net)
                  0.11    0.00   18.93 v hold600/A (sky130_fd_sc_hd__clkbuf_2)
                  0.15    0.24   19.17 v hold600/X (sky130_fd_sc_hd__clkbuf_2)
     6    0.04                           net912 (net)
                  0.15    0.00   19.18 v fanout205/A (sky130_fd_sc_hd__clkbuf_4)
                  0.04    0.20   19.37 v fanout205/X (sky130_fd_sc_hd__clkbuf_4)
. . . . . . . . . . . .
     1    0.00                           net390 (net)
                  0.05    0.00   25.83 ^ hold340/A (sky130_fd_sc_hd__dlygate4sd3_1)
                  0.06    0.57   26.40 ^ hold340/X (sky130_fd_sc_hd__dlygate4sd3_1)
     1    0.00                           net652 (net)
                  0.06    0.00   26.40 ^ _716_/D (sky130_fd_sc_hd__dfxtp_4)
                                 26.40   data arrival time

                         30.00   30.00   clock clk (rise edge)
                          4.50   34.50   clock source latency
                  0.60    0.00   34.50 ^ wb_clk_i (in)
     1    0.01                           wb_clk_i (net)
                  0.60    0.00   34.50 ^ _342_/A1 (sky130_fd_sc_hd__mux2_1)
                  0.67    0.64   35.14 ^ _342_/X (sky130_fd_sc_hd__mux2_1)
     2    0.08                           count.clk (net)
                  0.67    0.02   35.16 ^ clkbuf_0_count.clk/A (sky130_fd_sc_hd__clkbuf_16)
                  0.13    0.32   35.48 ^ clkbuf_0_count.clk/X (sky130_fd_sc_hd__clkbuf_16)
    16    0.11                           clknet_0_count.clk (net)
                  0.13    0.01   35.49 ^ clkbuf_3_1_0_count.clk/A (sky130_fd_sc_hd__clkbuf_8)
                  0.07    0.17   35.66 ^ clkbuf_3_1_0_count.clk/X (sky130_fd_sc_hd__clkbuf_8)
     6    0.03                           clknet_3_1_0_count.clk (net)
                  0.07    0.00   35.66 ^ _716_/CLK (sky130_fd_sc_hd__dfxtp_4)
                         -0.25   35.41   clock uncertainty
                          0.00   35.41   clock reconvergence pessimism
                         -0.06   35.35   library setup time
                                 35.35   data required time
-----------------------------------------------------------------------------
                                 35.35   data required time
                                -26.40   data arrival time
-----------------------------------------------------------------------------
                                  8.95   slack (MET)
. . . . . . . . . . . .
```

## Appendix B.4. A fragment of **33-rcx_sta.min.rpt** report: timing path details / hold

```
===========================================================================
report_checks -path_delay min (Hold)
============================================================================
======================= Typical Corner ===================================

Startpoint: _731_ (rising edge-triggered flip-flop clocked by clk)
Endpoint: _700_ (rising edge-triggered flip-flop clocked by clk)
Path Group: clk
Path Type: min

Fanout     Cap    Slew   Delay    Time   Description
-----------------------------------------------------------------------------
                          0.00    0.00   clock clk (rise edge)
                          4.50    4.50   clock source latency
                  0.60    0.00    4.50 ^ wb_clk_i (in)
     1    0.01                           wb_clk_i (net)
                  0.60    0.00    4.50 ^ _342_/A1 (sky130_fd_sc_hd__mux2_1)
                  0.67    0.64    5.14 ^ _342_/X (sky130_fd_sc_hd__mux2_1)
     2    0.08                           count.clk (net)
                  0.67    0.02    5.16 ^ clkbuf_0_count.clk/A (sky130_fd_sc_hd__clkbuf_16)
                  0.13    0.32    5.48 ^ clkbuf_0_count.clk/X (sky130_fd_sc_hd__clkbuf_16)
    16    0.11                           clknet_0_count.clk (net)
                  0.13    0.01    5.49 ^ clkbuf_3_6_0_count.clk/A (sky130_fd_sc_hd__clkbuf_8)
                  0.14    0.22    5.71 ^ clkbuf_3_6_0_count.clk/X (sky130_fd_sc_hd__clkbuf_8)
    22    0.08                           clknet_3_6_0_count.clk (net)
                  0.14    0.01    5.72 ^ _731_/CLK (sky130_fd_sc_hd__dfxtp_4)
                  0.21    0.47    6.19 ^ _731_/Q (sky130_fd_sc_hd__dfxtp_4)
    10    0.07                           net142 (net)
                  0.21    0.00    6.19 ^ hold769/A (sky130_fd_sc_hd__dlygate4sd3_1)
                  0.06    0.55    6.74 ^ hold769/X (sky130_fd_sc_hd__dlygate4sd3_1)
     1    0.00                           net1081 (net)
                  0.06    0.00    6.74 ^ hold578/A (sky130_fd_sc_hd__dlygate4sd3_1)
                  0.08    0.54    7.27 ^ hold578/X (sky130_fd_sc_hd__dlygate4sd3_1)
     1    0.01                           net890 (net)
                  0.08    0.00    7.27 ^ _368_/A0 (sky130_fd_sc_hd__mux2_1)
                  0.04    0.12    7.39 ^ _368_/X (sky130_fd_sc_hd__mux2_1)
     1    0.00                           _018_ (net)
                  0.04    0.00    7.39 ^ hold195/A (sky130_fd_sc_hd__dlygate4sd3_1)
                  0.06    0.51    7.90 ^ hold195/X (sky130_fd_sc_hd__dlygate4sd3_1)
     1    0.00                           net507 (net)
                  0.06    0.00    7.90 ^ _700_/D (sky130_fd_sc_hd__dfxtp_1)
                                  7.90   data arrival time

                          0.00    0.00   clock clk (rise edge)
                          6.00    6.00   clock source latency
                  0.60    0.00    6.00 ^ wb_clk_i (in)
     1    0.01                           wb_clk_i (net)
                  0.60    0.00    6.00 ^ _342_/A1 (sky130_fd_sc_hd__mux2_1)
                  0.67    0.71    6.71 ^ _342_/X (sky130_fd_sc_hd__mux2_1)
     2    0.08                           count.clk (net)
                  0.68    0.02    6.73 ^ clkbuf_0_count.clk/A (sky130_fd_sc_hd__clkbuf_16)
                  0.13    0.36    7.09 ^ clkbuf_0_count.clk/X (sky130_fd_sc_hd__clkbuf_16)
    16    0.11                           clknet_0_count.clk (net)
                  0.13    0.01    7.10 ^ clkbuf_3_6_0_count.clk/A (sky130_fd_sc_hd__clkbuf_8)
                  0.14    0.24    7.34 ^ clkbuf_3_6_0_count.clk/X (sky130_fd_sc_hd__clkbuf_8)
    22    0.08                           clknet_3_6_0_count.clk (net)
                  0.14    0.00    7.34 ^ _700_/CLK (sky130_fd_sc_hd__dfxtp_1)
                          0.25    7.59   clock uncertainty
                         -1.63    5.96   clock reconvergence pessimism
                         -0.02    5.94   library hold time
                                  5.94   data required time
-----------------------------------------------------------------------------
                                  5.94   data required time
                                 -7.90   data arrival time
-----------------------------------------------------------------------------
                                  1.96   slack (MET)
```

## Appendix B.5. A fragment of **33-rcx_sta.power.rpt** report: power estimation

Leakage power is proportional to area, but it is not clear to me how Open Lane computes switching power without stimulus of some sort. Is it propagating some switching from I/O pins, or does it assume some default switching?

```
===========================================================================
 report_power
============================================================================
======================= Typical Corner ===================================

Group                  Internal  Switching    Leakage      Total
                          Power      Power      Power      Power (Watts)
----------------------------------------------------------------
Sequential             4.48e-05   2.37e-05   5.25e-10   6.85e-05  11.2%
Combinational          2.26e-04   3.14e-04   1.06e-07   5.41e-04  88.8%
Macro                  0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%
Pad                    0.00e+00   0.00e+00   0.00e+00   0.00e+00   0.0%
----------------------------------------------------------------
Total                  2.71e-04   3.38e-04   1.06e-07   6.09e-04 100.0%
                          44.5%      55.5%       0.0%
```

## Appendix C.1. Log for unsuccessful run 'make user_project_wrapper' under Lubuntu LTS 24.04

This run probably suffered from low disk space, but it is not clear from the error message.

```
make user_project_wrapper
```

```
make -C openlane user_project_wrapper
make[1]: Entering directory '/home/verilog/projects/caravel_user_project_experiment/openlane'
/home/verilog/projects/caravel_user_project_experiment/venv/bin/volare enable 78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc
Version 78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc enabled for the sky130 PDK.
# user_project_wrapper
mkdir -p ./user_project_wrapper/runs/24_12_28_10_34 
rm -rf ./user_project_wrapper/runs/user_project_wrapper
ln -s $(realpath ./user_project_wrapper/runs/24_12_28_10_34) ./user_project_wrapper/runs/user_project_wrapper
docker run -it -u $(id -u $USER):$(id -g $USER) -v $(realpath /home/verilog/projects/caravel_user_project_experiment/..):$(realpath /home/verilog/projects/caravel_user_project_experiment/..) -v /home/verilog/projects/caravel_user_project_experiment/dependencies/pdks:/home/verilog/projects/caravel_user_project_experiment/dependencies/pdks -v /home/verilog/projects/caravel_user_project_experiment/caravel:/home/verilog/projects/caravel_user_project_experiment/caravel -v /home/verilog/.ipm:/home/verilog/.ipm -v /home/verilog/projects/caravel_user_project_experiment/dependencies/openlane_src:/openlane -v /home/verilog/projects/caravel_user_project_experiment/mgmt_core_wrapper:/home/verilog/projects/caravel_user_project_experiment/mgmt_core_wrapper -e PDK_ROOT=/home/verilog/projects/caravel_user_project_experiment/dependencies/pdks -e PDK=sky130A -e MISMATCHES_OK=1 -e CARAVEL_ROOT=/home/verilog/projects/caravel_user_project_experiment/caravel -e OPENLANE_RUN_TAG=24_12_28_10_34 -e MCW_ROOT=/home/verilog/projects/caravel_user_project_experiment/mgmt_core_wrapper  \
	efabless/openlane:2023.07.19-1 sh -c "flow.tcl -design $(realpath ./user_project_wrapper) -save_path $(realpath ..) -save -tag 24_12_28_10_34 -overwrite -ignore_mismatches"
OpenLane 30ee1388932eb55a89ad84ee43997bfe3a386421
All rights reserved. (c) 2020-2022 Efabless Corporation and contributors.
Available under the Apache License, version 2.0. See the LICENSE file for more details.

[36m[INFO]: Using configuration in '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/config.json'...[39m
[36m[INFO]: PDK Root: /home/verilog/projects/caravel_user_project_experiment/dependencies/pdks[39m
[36m[INFO]: Process Design Kit: sky130A[39m
[36m[INFO]: Standard Cell Library: sky130_fd_sc_hd[39m
[36m[INFO]: Optimization Standard Cell Library: sky130_fd_sc_hd[39m
[36m[INFO]: Run Directory: /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34[39m
[36m[INFO]: Saving runtime environment...[39m
[36m[INFO]: Preparing LEF files for the nom corner...[39m
[36m[INFO]: Preparing LEF files for the min corner...[39m
[36m[INFO]: Preparing LEF files for the max corner...[39m
[STEP 1]
[36m[INFO]: Running Synthesis (log: ../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/logs/synthesis/1-synthesis.log)...[39m
[31m[ERROR]: during executing yosys script /openlane/scripts/yosys/elaborate.tcl[39m
[31m[ERROR]: Log: ../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/logs/synthesis/1-synthesis.log[39m
[31m[ERROR]: Last 10 lines:
[TCL: yosys -import] Command name collision: found pre-existing command `eval' -> skip.
[TCL: yosys -import] Command name collision: found pre-existing command `exec' -> skip.
[TCL: yosys -import] Command name collision: found pre-existing command `read' -> skip.
[TCL: yosys -import] Command name collision: found pre-existing command `trace' -> skip.

1. Executing Liberty frontend: /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/../../lib/user_proj_example.lib
Imported 1 cell types from liberty file.

2. Executing Verilog-2005 frontend: /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/../../verilog/gl/user_proj_example.v
child killed: kill signal
[39m
[31m[ERROR]: Creating issue reproducible...[39m
[36m[INFO]: Saving runtime environment...[39m
OpenLane TCL Issue Packager

EFABLESS CORPORATION AND ALL AUTHORS OF THE OPENLANE PROJECT SHALL NOT BE HELD
LIABLE FOR ANY LEAKS THAT MAY OCCUR TO ANY PROPRIETARY DATA AS A RESULT OF USING
THIS SCRIPT. THIS SCRIPT IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND.

BY USING THIS SCRIPT, YOU ACKNOWLEDGE THAT YOU FULLY UNDERSTAND THIS DISCLAIMER
AND ALL IT ENTAILS.

Parsing config file(s)…
Setting up /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/issue_reproducible…
Done.
[36m[INFO]: Reproducible packaged: Please tarball and upload '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/issue_reproducible' if you're going to submit an issue.[39m
[31m[ERROR]: Step 1 (synthesis) failed with error:
-code 1 -level 0 -errorcode NONE -errorinfo {
    while executing
"throw_error"
    (procedure "run_tcl_script" line 219)
    invoked from within
"run_tcl_script -tool yosys -no_consume {*}$args"
    (procedure "run_yosys_script" line 2)
    invoked from within
"run_yosys_script $::env(SYNTH_SCRIPT) -indexed_log $arg_values(-indexed_log)"
    (procedure "run_yosys" line 44)
    invoked from within
"run_yosys -indexed_log $log"
    (procedure "run_synthesis" line 13)
    invoked from within
"run_synthesis"} -errorline 1[39m
[36m[INFO]: Saving current set of views in '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/results/final'...[39m
[36m[INFO]: Generating final set of reports...[39m
[36m[INFO]: Created manufacturability report at '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/reports/manufacturability.rpt'.[39m
[36m[INFO]: Created metrics report at '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_10_34/reports/metrics.csv'.[39m
[36m[INFO]: Saving runtime environment...[39m
[31m[ERROR]: Flow failed.[39m
make[1]: *** [Makefile:80: user_project_wrapper] Error 255
make[1]: Leaving directory '/home/verilog/projects/caravel_user_project_experiment/openlane'
make: *** [Makefile:126: user_project_wrapper] Error 2
```

## Appendix C.2. Log 1 for unsuccessful run 'make user_project_wrapper' under Simply Linux 10.4

```
make user_project_wrapper
```

```
. . . . . . . . . . . . . . .
[STEP 1]
[36m[INFO]: Running Synthesis (log: ../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/logs/synthesis/1-synthesis.log)...[39m
[31m[ERROR]: during executing yosys script /openlane/scripts/yosys/elaborate.tcl[39m
[31m[ERROR]: Log: ../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/logs/synthesis/1-synthesis.log[39m
[31m[ERROR]: Last 10 lines:
[TCL: yosys -import] Command name collision: found pre-existing command `eval' -> skip.
[TCL: yosys -import] Command name collision: found pre-existing command `exec' -> skip.
[TCL: yosys -import] Command name collision: found pre-existing command `read' -> skip.
[TCL: yosys -import] Command name collision: found pre-existing command `trace' -> skip.

1. Executing Liberty frontend: /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/../../lib/user_proj_example.lib
Imported 1 cell types from liberty file.

2. Executing Verilog-2005 frontend: /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/../../verilog/gl/user_proj_example.v
child killed: kill signal
[39m
[31m[ERROR]: Creating issue reproducible...[39m
[36m[INFO]: Saving runtime environment...[39m
OpenLane TCL Issue Packager

EFABLESS CORPORATION AND ALL AUTHORS OF THE OPENLANE PROJECT SHALL NOT BE HELD
LIABLE FOR ANY LEAKS THAT MAY OCCUR TO ANY PROPRIETARY DATA AS A RESULT OF USING
THIS SCRIPT. THIS SCRIPT IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND.

BY USING THIS SCRIPT, YOU ACKNOWLEDGE THAT YOU FULLY UNDERSTAND THIS DISCLAIMER
AND ALL IT ENTAILS.

Parsing config file(s)…
Setting up /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/issue_reproducible…
Done.
[36m[INFO]: Reproducible packaged: Please tarball and upload '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/issue_reproducible' if you're going to submit an issue.[39m
[31m[ERROR]: Step 1 (synthesis) failed with error:
-code 1 -level 0 -errorcode NONE -errorinfo {
    while executing
"throw_error"
    (procedure "run_tcl_script" line 219)
    invoked from within
"run_tcl_script -tool yosys -no_consume {*}$args"
    (procedure "run_yosys_script" line 2)
    invoked from within
"run_yosys_script $::env(SYNTH_SCRIPT) -indexed_log $arg_values(-indexed_log)"
    (procedure "run_yosys" line 44)
    invoked from within
"run_yosys -indexed_log $log"
    (procedure "run_synthesis" line 13)
    invoked from within
"run_synthesis"} -errorline 1[39m
[36m[INFO]: Saving current set of views in '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/results/final'...[39m
[36m[INFO]: Generating final set of reports...[39m
[36m[INFO]: Created manufacturability report at '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/reports/manufacturability.rpt'.[39m
[36m[INFO]: Created metrics report at '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/24_12_28_19_26/reports/metrics.csv'.[39m
[36m[INFO]: Saving runtime environment...[39m
[31m[ERROR]: Flow failed.[39m
make[1]: *** [Makefile:80: user_project_wrapper] Error 255
make[1]: Leaving directory '/home/verilog/projects/caravel_user_project_experiment/openlane'
make: *** [Makefile:126: user_project_wrapper] Error 2
```

## Appendix C.3. Log 2 for unsuccessful run 'make user_project_wrapper' under Simply Linux 10.4

```
make user_project_wrapper
```

```
. . . . . . . . . . . . . . .
[STEP 25]
[36m[INFO]: Running XOR on the layouts using KLayout (log: ../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/logs/signoff/25-xor.log)...[39m
[31m[ERROR]: during executing: "klayout -b -r /openlane/scripts/klayout/xor.drc -rd a=/home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/results/signoff/user_project_wrapper.gds -rd b=/home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/results/signoff/user_project_wrapper.klayout.gds -rd jobs=1 -rd rdb_out=/home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/reports/signoff/25-xor.xml -rd ignore=81/14 -rd rpt_out=/home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/reports/signoff/25-xor.rpt |& tee /dev/null /home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/logs/signoff/25-xor.log"[39m
[31m[ERROR]: Exit code: 1[39m
[31m[ERROR]: Last 10 lines:
    Elapsed: 0.010s  Memory: 2169.00M
--- Running XOR for layer 67/44 ---
"input" in: xor.drc:94
    Polygons (raw): 7749766 (flat)  3222 (hierarchical)
    Elapsed: 0.000s  Memory: 2169.00M
"input" in: xor.drc:94
    Polygons (raw): 15497204 (flat)  4116 (hierarchical)
    Elapsed: 0.000s  Memory: 2169.00M
"^" in: xor.drc:94
child killed: kill signal
[39m
[31m[ERROR]: Step 25 (gds_klayout) failed with error:
-code 1 -level 0 -errorcode NONE -errorinfo {
    while executing
"throw_error"
    (procedure "try_exec" line 17)
    invoked from within
"try_exec klayout  -b  -r $::env(SCRIPTS_DIR)/klayout/xor.drc  -rd a=$arg_values(-layout1)  -rd b=$arg_values(-layout2)  -rd jobs=$::env(KLAYOUT_XOR_TH..."
    (procedure "run_klayout_gds_xor" line 23)
    invoked from within
"run_klayout_gds_xor"
    (procedure "run_klayout_step" line 6)
    invoked from within
"run_klayout_step"} -errorline 1[39m
[36m[INFO]: Saving current set of views in '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/results/final'...[39m
[36m[INFO]: Generating final set of reports...[39m
[36m[INFO]: Created manufacturability report at '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/reports/manufacturability.rpt'.[39m
[36m[INFO]: Created metrics report at '../home/verilog/projects/caravel_user_project_experiment/openlane/user_project_wrapper/runs/25_01_18_20_44/reports/metrics.csv'.[39m
[36m[INFO]: Saving runtime environment...[39m
[31m[ERROR]: Flow failed.[39m
[36m[INFO]: The failure may have been because of the following warnings:[39m
[WARNING]: Module sky130_fd_sc_hd__fill_1 blackboxed during sta
[WARNING]: Module sky130_ef_sc_hd__decap_12 blackboxed during sta
[WARNING]: Module sky130_fd_sc_hd__fill_2 blackboxed during sta
[WARNING]: Module sky130_fd_sc_hd__tapvpwrvgnd_1 blackboxed during sta
[WARNING]: VSRC_LOC_FILES is not defined. The IR drop analysis will run, but the values may be inaccurate.

make[1]: *** [Makefile:80: user_project_wrapper] Error 255
make[1]: Leaving directory '/home/verilog/projects/caravel_user_project_experiment/openlane'
make: *** [Makefile:126: user_project_wrapper] Error 2
```
