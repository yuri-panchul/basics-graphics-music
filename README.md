# `basics-graphics-music`: A collection of portable Verilog examples for FPGA and ASIC design

**YURI: This text has to be edited**

These are examples to demonstrate labs sessions for [systemverilog-homework](https://github.com/yuri-panchul/systemverilog-homework) which are portable [SystemVerilog](https://en.wikipedia.org/wiki/SystemVerilog)
examples for FPGA and ASIC.

> [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) Field Programmable Gate Array is a type of integrated circuit that can be programmed multiple times.
It consists of an array of programmable logic blocks and interconnects that can be configured to perform
various digital functions. FPGAs are commonly used in applications where flexibility, speed, and parallel
processing capabilities are required, such as in telecommunications, automotive and aerospace.

> [ASIC](https://en.wikipedia.org/wiki/Application-specific_integrated_circuit), Application Specific Integrated Circuit, this is an integrated circuit chip designed for specific use
for instance, telecommunications, automotive etc.

These examples facilitate learning for beginners by:-

1. Removing EDA and FPGA vendor complexity and restrictions.
2. Compensating the gap between academia and industry in solving microarchitectural problems necessary for a career in ASIC design, building CPU, GPU and networking chips.
3. Reducing the barrier of entry for them or a person who is transitioning to FPGA/ASIC design.

# Getting Started

You only need a few things to get started:

1. Get [a compatible FPGA board](#compatible-hardware).
2. Install [drivers and required software](#supported-boards).
3. Download or checkout this repository on 
   [Windows](#Windows), [Linux](#Linux), or [macOS](#macOS).
4. Run [`06_choose_another_fpga_board.bash`](./labs/1_basics/1_01_and_or_not_xor_de_morgan/06_choose_another_fpga_board.bash) to select your board.
5. Run [`03_synthesize_for_fpga.bash`](./labs/1_basics/1_01_and_or_not_xor_de_morgan/03_synthesize_for_fpga.bash) to synthesize, place, and program your board all in one go.

That's it! You're now running Verilog example code on real hardware. 
Press buttons on the board and check for LEDs to light up accordingly.

## First time setup

1. Follow the instructions for [Windows](#Windows), [Linux](#Linux), or [macOS](#macOS) to set up your environment.
1. Optional: Configure _VSCode_:
   1. Install these extensions: _:wrench: TODO: Verilog extensions configuration_
   1. Recommended extensions: _GitHub Pull Requests_ and _GitHub Repositories_
1. Checkout this GitHub repository. Check out 
   [Git Cheat Sheet](./git_cheat_sheet.md) if you need additional help
   > Optionally, switch to a `new_graphics` branch to get access to
   the bleeding edge features.
1. Select the right board:
    ```bash
    cd ./labs/1_basics/1_01_and_or_not_xor_de_morgan/
    ./06_choose_another_fpga_board.bash
    ``` 
    Type number corresponding to your board and press _Enter_.
1. Synthesize, place and program the board using a 
   [_Git Bash_](#Open-a-_Git-Bash_-terminal):
    ```bash
    cd ./labs/1_basics/1_01_and_or_not_xor_de_morgan/
    ./03_synthesize_for_fpga.bash
    ```
    If all goes well, you should see the LEDs on your 
    board light up according to the example.
    
As long as you do not change your hardware, you only need to
run `03_synthesize_for_fpga.bash` script after the first time setup.

## Windows

> Examples are not fully compatible with a WSL.
You're welcome to try at your own risk and peril.
See [documentation](./docs/wsl.md).

* Required: Download and install [Git for Windows](https://git-scm.com/download/win).
  * :warning: We recommend on the _"Adjusting your PATH environment"_ step to select 
    _"Use Git and optional Unix tools from the Windows Command Prompt"_.    
* Required: Bash: Compatibility is only verified with Bash installed as part of the [Git for Windows](https://git-scm.com/download/win) package.
* Recommended: Download and install 
      [VScode](https://apps.microsoft.com/detail/xp9khm4bk9fz7q)

:warning: Examples and scripts can _only_ be run with a _Git Bash_ terminal. 
There are mutliple different options to open it.
Choose one that works best for you:

* Open _Git Bash_ from the Start menu or from 
  a right-click context menu in any folder (if you enabled it during installation).
* Alternatively, you can use VSCode:  
   * Optionally: Set it as a default in _Settings > Features > Terminal > Integrated > Default Profile > Windows > Git Bash_.
   * Open a new _Git Bash_ as a one-off
     by clikcing on the dropdown arrow next to the plus icon in the terminal panel and selecting _Git Bash_.

You can tell that it's a _Git Bash_ terminal if you see a prompt that looks like this:
```bash
user@hostname MINGW64 /c/Users/user/Documents/basics-graphics-music/ (master)
$ 
```


## Linux

You may need to install git if not alredy installed:
```bash
sudo apt-get install git
```

You can use any terminal including built-in.

## macOS

No special stesps are required. You can use any terminal including built-in.

* Optional: If you hit issues with `bash`, you may have a version older than
  is currently supported. If so, you can use 
  [Homebrew](https://brew.sh/)'s `bash` instead:
    ```bash
    brew install bash
    ```

# Compatible Hardware

To support educators worldwide, we support a wide variety of hardware across all manufacturers and price ranges, with several dozen different variants in total. See [./boards](./boards/) for more information.

If you do not know where to start:
* [Gowin SiPeed Tang Nano 9K](https://www.gowinsemi.com/en/support/devkits_detail/43/) is a solid and affordable starter board.

## Supported Boards

> :wrench: Work in progress. Only a few out of dozens of supported boards are documented.
Your contributions are welcome.

* Compatibility: :apple: macOS, :penguin: Linux, :computer: Windows, :globe_with_meridians: Open Source

| Chip          | Board                | Variants                                             | Software                                           |
|---------------|----------------------|------------------------------------------------------|----------------------------------------------------|
| Altera MAX 10 | Terasic DE10-Lite    | [`de10_lite`](./boards/de10_lite/)                   | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Gowin GW1NR-9 | Sipeed Tang Nano 20K | [`tang_nano_20k_lcd_800_480_tm1638`](./boards/tang_nano_20k_lcd_800_480_tm1638/) | [Gowin EDA](./docs/GowinEDA.md)                    |

# Verilog Events Across the World

This repository was used during the following events:

[Hacker Dojo in Mountain View, California in 2024](https://verilog-meetup.com)

![Hacker Dojo in Mountain View, California in 2024](https://github.com/yuri-panchul/basics-graphics-music/blob/main/misc/2024_hacker_dojo.jpg)

[ADA University in Baku, Azerbaijan in 2024](https://verilog-meetup.com/2024/02/28/azerbaijan-2024/)

![ADA University in Baku, Azerbaijan in 2024](https://github.com/yuri-panchul/basics-graphics-music/blob/main/misc/2024_ada_baku.jpg)

[LaLambda 2023 in Tbilisi, Georgia](https://lalambda.school)

![LaLambda 2023 in Tbilisi, Georgia](https://github.com/yuri-panchul/basics-graphics-music/blob/main/misc/2023_lalambda_tbilisi.jpg)

[AUCA & Siemens EDA seminar in Bishkek, Kyrgyzstan in 2022](https://ddvca.com)

![AUCA & Siemens EDA seminar in Bishkek, Kyrgyzstan in 2022](https://github.com/yuri-panchul/basics-graphics-music/blob/main/misc/2022_auca_bishkek.jpg)

[Школа синтеза цифровых схем / The School of Synthesis of the Digital Circuits, 2020](https://engineer.yadro.com/chip-design-school)

![Школа синтеза цифровых схем / The School of Synthesis of the Digital Circuits, 2020](https://github.com/yuri-panchul/basics-graphics-music/blob/main/misc/2023_synthesis_school_russia_belarus.png)
