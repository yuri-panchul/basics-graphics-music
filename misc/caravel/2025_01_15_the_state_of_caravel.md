# The State of Caravel: the First Look
Yuri Panchul, 2025.1.15

## 1. Caravel as a tool to train balancing microarchitecture and timing

Before joining an electronic company, a student who aims to become an RTL engineer - should be trained in developing pipelined designs. Not just a traditional 5-stage pipelined CPU, but pipelined data processing used in networking chips, GPUs and ML accelerators.

Such training requires doing a lot of exercises using a Verilog simulator to learn the tricks of maximizing bandwidth. However, learning microarchitecture without developing intuition about static timing analysis does not make sense: the students have to synthesize their designs to make sure the pipeline does not break the timing.

This is usually done in FPGA labs, however FPGA timing and utilization are different from ASICs, so here is another option: using eFabless Caravel infrastructure on the top of the Open Lane ASIC RTL-to-GDSII toolchain.

## 2. The Usage Scenario

The presumed usage scenario is:

We get a group of students who do Verilog simulation exercises using systemverilog-homework exercises and FPGA labs using basics-graphics-music (BGM) repository.
At some point, the students create their own designs using the BGM framework that isolates the students from FPGA vendor-specific details. Once a student’s design works on an FPGA board, the student can transfer his board-independent modules into a modified Caravel infrastructure.
The group can pack 15-30 designs into one Caravel or Caravel-Mini, depending on the required area and the costs. Glue logic, together with a housekeeping RISC-V core, can activate only one design at a time.
Alternatively, instead of making individual designs, the student team can work on a larger project, such as a mid-range CPU core with caches and MMU. In this way, the students can learn how to cooperate in a setting similar to an industrial team.
While working on a Caravel-based project, a student may re-engineer his pipelines to meet area and timing budgets. Eventually, the whole group will do a tapeout and get their chip manufactured in a few months.

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

https://github.com/yuri-panchul/caravel_user_mini_experiment is generated from https://github.com/efabless/caravel_user_mini
https://github.com/yuri-panchul/caravel_user_project_experiment is generated https://github.com/efabless/caravel_user_project

### 4.3. Step 2. Setup

I did the setup on 5 platforms: Ubuntu 24.04 LTS, Lubuntu 24.04 LTS, Simply Linux 10.4, Windows 11 with WSL (Windows Subsystem Linux) Ubuntu and MacOS on Apple Silicon (Mac Mini 4).

#### 4.3.1. Setup on Ubuntu 24.04 LTS

First, three dependencies were missing: make, python3-pip and docker. I installed the first two using apt-get and docker using the instruction from https://docs.docker.com/engine/install/ubuntu .
However it was not sufficient; I also had to use systemctl and gpasswd commands. Finally, I had to install a Python virtual environment using “sudo apt install python3.12-venv”. After this, “make setup” worked.

See Appendix A. Ubuntu setup commands for more details.

## Appendix A. Ubuntu setup commands

```bash
sudo apt install make
sudo apt-get install python3-pip -y

https://docs.docker.com/engine/install/ubuntu/

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

sudo systemctl start docker
sudo systemctl enable docker
sudo gpasswd -a $USER docker

sudo apt install python3.12-venv
make setup
```
