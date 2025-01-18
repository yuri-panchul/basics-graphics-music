# The State of Caravel: the First Look
Yuri Panchul, 2025.1.15

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

Setup on Simply Linux worked without any problems, but this was probably due to the fact that I already had Open Lane up and running on my Simply Linux installation which was prepared by Anton Midyukov, a maintainer of Simply Linux distribution.

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

```
Leakage power is proportional to area, but it is not clear to me how Open Lane computes switching power without stimulus of some sort. Is it propagating some switching from I/O pins, or does it assume some default switching?

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
