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

> :wrench: Work in progress. Please, double-check information for your board online.
Your contributions are welcome.

| FPGA Chip          | Board                | Variants                                             | Software                                           |
|--------------------|----------------------|------------------------------------------------------|----------------------------------------------------|
| Altera Cyclone II  | Terasic DE1          | [`de1`](./boards/de1/)                               | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone II  | Terasic DE2          | [`de2`](./boards/de2/)                               | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone III | Terasic DE0          | [`de0`](./boards/de0/)                               | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone III | Altera DK-DEV-3C120N | [`dk_dev_3c120n`](./boards/dk_dev_3c120n/)           | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone IV  | Alinx AX4010         | [`alinx_ax4010`](./boards/alinx_ax4010/)             | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone IV  | Terasic DE0-Nano     | [`de0_nano_vga_pmod`](./boards/de0_nano_vga_pmod/) <br/> [`de0_nano_vga666`](./boards/de0_nano_vga666/) | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone IV  | Zeowaa               | [`zeowaa`](./boards/zeowaa/) <br/> [`zeowaa_wo_dig_0`](./boards/zeowaa_wo_dig_0/) |                                                    |
| Altera Cyclone IV  | Terasic DE2-115      | [`de2_115`](./boards/de2_115/)                       | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone V   | Terasic DE0-CV       | [`de0_cv`](./boards/de0_cv/)                         | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone V   | Terasic DE10-Nano    | [`de10_nano`](./boards/de10_nano/)                   | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone V SoC | Terasic DE0-Nano SoC | [`de0_nano_soc_vga_pmod`](./boards/de0_nano_soc_vga_pmod/) <br/> [`de0_nano_soc_vga666`](./boards/de0_nano_soc_vga666/) | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone V SoC | Terasic DE1-SoC    | [`de1_soc`](./boards/de1_soc/)                       | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera Cyclone V GX | Terasic C5GX        | [`c5gx`](./boards/c5gx/)                             | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Altera MAX 10      | Terasic DE10-Lite    | [`de10_lite`](./boards/de10_lite/)                   | [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Emooc              | CC                   | [`emooc_cc`](./boards/emooc_cc/)                     |                                                    |
| Gowin GW5AST-LV138 | [SiPeed Tang Mega 138K](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k.html) | [`tang_mega_138k_lcd_480_272_tm1638`](./boards/tang_mega_138k_lcd_480_272_tm1638/) <br/> [`tang_mega_138k_pro_lcd_480_272_no_tm1638`](./boards/tang_mega_138k_pro_lcd_480_272_no_tm1638/) <br/> [`tang_mega_138k_pro_lcd_480_272_tm1638`](./boards/tang_mega_138k_pro_lcd_480_272_tm1638/) | [Gowin EDA](./docs/GowinEDA.md) |
| Gowin GW1NR-9      | [SiPeed Tang Nano 9K](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html) | [`tang_nano_9k_lcd_480_272_no_tm1638_yosys`](./boards/tang_nano_9k_lcd_480_272_no_tm1638_yosys/) <br/> [`tang_nano_9k_lcd_480_272_tm1638`](./boards/tang_nano_9k_lcd_480_272_tm1638/) <br/> [`tang_nano_9k_lcd_480_272_tm1638_yosys`](./boards/tang_nano_9k_lcd_480_272_tm1638_yosys/) <br/> [`tang_nano_9k_lcd_800_480_no_tm1638`](./boards/tang_nano_9k_lcd_800_480_no_tm1638/) <br/> [`tang_nano_9k_lcd_800_480_no_tm1638_yosys`](./boards/tang_nano_9k_lcd_800_480_no_tm1638_yosys/) <br/> [`tang_nano_9k_lcd_800_480_tm1638`](./boards/tang_nano_9k_lcd_800_480_tm1638/) <br/> [`tang_nano_9k_lcd_800_480_tm1638_yosys`](./boards/tang_nano_9k_lcd_800_480_tm1638_yosys/) <br/> [`tang_nano_9k_lcd_ml6485_no_tm1638_yosys`](./boards/tang_nano_9k_lcd_ml6485_no_tm1638_yosys/) <br/> [`tang_nano_9k_lcd_ml6485_tm1638_yosys`](./boards/tang_nano_9k_lcd_ml6485_tm1638_yosys/) | [Gowin EDA](./docs/GowinEDA.md) <br/> [Yosys](./docs/Yosys.md) |
| Gowin GW2A-LV18    | [SiPeed Tang Primer 20K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-20k/primer-20k.html) | [`tang_primer_20k_dock_hdmi_no_tm1638`](./boards/tang_primer_20k_dock_hdmi_no_tm1638/) <br/> [`tang_primer_20k_dock_hdmi_tm1638`](./boards/tang_primer_20k_dock_hdmi_tm1638/) <br/> [`tang_primer_20k_dock_no_hdmi_no_tm1638`](./boards/tang_primer_20k_dock_no_hdmi_no_tm1638/) <br/> [`tang_primer_20k_dock_no_hdmi_tm1638`](./boards/tang_primer_20k_dock_no_hdmi_tm1638/) <br/> [`tang_primer_20k_lite`](./boards/tang_primer_20k_lite/) | [Gowin EDA](./docs/GowinEDA.md) |
| Gowin GW5A-LV25    | [SiPeed Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html) | [`tang_primer_25k`](./boards/tang_primer_25k/)       | [Gowin EDA](./docs/GowinEDA.md) |
| Gowin GW12AR-18    | [Sipeed Tang Nano 20K](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html) | [`tang_nano_20k_hdmi_tm1638`](./boards/tang_nano_20k_hdmi_tm1638/) <br/> [`tang_nano_20k_lcd_800_480_tm1638`](./boards/tang_nano_20k_lcd_800_480_tm1638/) | [Gowin EDA](./docs/GowinEDA.md) |
| Lattice ECP5       | [OrangeCrab](https://github.com/orangecrab-fpga/orangecrab-hardware) | [`orangecrab_ecp5_yosys`](./boards/orangecrab_ecp5_yosys/) | [Yosys](./docs/Yosys.md)                           |
| Lattice ECP5       | [Karnix](https://github.com/Fabmicro-LLC/Karnix_ASB-254) | [`karnix_ecp5_yosys`](./boards/karnix_ecp5_yosys/)   | [Yosys](./docs/Yosys.md)                           |
| Lattice iCE40      | [Lattice iCE40-HX8K](https://www.latticesemi.com/Products/DevelopmentBoardsAndKits/iCE40HX8KBreakoutBoard.aspx) | [`ice40hx8k_evb_yosys`](./boards/ice40hx8k_evb_yosys/) | [Yosys](./docs/Yosys.md)                           |
| Altera Cyclone IV  | Omdazz              | [`omdazz`](./boards/omdazz/) <br/> [`omdazz_pmod_mic3`](./boards/omdazz_pmod_mic3/) |  [Intel Quartus Prime Lite](./docs/IntelQuartus.md)                                                    |
| Altera Cyclone IV  | Rzrd                | [`rzrd`](./boards/rzrd/) <br/> [`rzrd_pmod_mic3`](./boards/rzrd_pmod_mic3/) | [Intel Quartus Prime Lite](./docs/IntelQuartus.md)                                                   |
| Xilinx Artix-7     | Arty A7             | [`arty_a7`](./boards/arty_a7/) <br/> [`arty_a7_pmod_mic3`](./boards/arty_a7_pmod_mic3/) | [Vivado](./docs/vivado_installation_guide/readme.md) |
| Xilinx Artix-7     | Basys 3             | [`basys3`](./boards/basys3/)                         | [Vivado](./docs/vivado_installation_guide/readme.md) |
| Xilinx Artix-7     | Nexys 4             | [`nexys4`](./boards/nexys4/)                         | [Vivado](./docs/vivado_installation_guide/readme.md) |
| Xilinx Artix-7     | Nexys 4 DDR         | [`nexys4_ddr`](./boards/nexys4_ddr/)                 | [Vivado](./docs/vivado_installation_guide/readme.md) |
| Xilinx Artix-7     | Nexys A7            | [`nexys_a7`](./boards/nexys_a7/)                     | [Vivado](./docs/vivado_installation_guide/readme.md) |
| Altera Cyclone IV  | Pisword S6          | [`piswords6`](./boards/piswords6/)                   | [Intel Quartus Prime Lite](./docs/IntelQuartus.md)   |
| Altera Cyclone IV  | Saylinx             | [`saylinx`](./boards/saylinx/) <br/> [`saylinx_pmod_mic3`](./boards/saylinx_pmod_mic3/) |  [Intel Quartus Prime Lite](./docs/IntelQuartus.md) |
| Xilinx Kintex 7    | [QMTech Kintex 7](https://github.com/carlosedp/QMTechBaseBoard) | [`qmtech_kintex_7`](./boards/qmtech_kintex_7/)       | [Vivado](./docs/vivado_installation_guide/readme.md) |
| Xilinx Zynq-7000   | Zybo Z7             | [`zybo_z7`](./boards/zybo_z7/)                       | [Vivado](./docs/vivado_installation_guide/readme.md) |
### External hardware

Not all boards include everything on the same board. To compensate for this we use external boards and hardware to extend input and output capabilities. The most common external hardware is:

* All variants: [INMP441](https://www.aliexpress.us/item/3256803154251183.html) [I2S](https://en.wikipedia.org/wiki/I%C2%B2S) microphone
* Almost all variants: PCM5102 [I2S](https://en.wikipedia.org/wiki/I%C2%B2S) stereo audio DAC.
  Some boards do not require an external DAC as they have an on-board DAC (Tang Nano 20K)
* `tm1638` or `no_tm1638`: with and without [TM1638](https://www.aliexpress.us/item/3256802635508991.html): 8-digit 7-segment display with 8 buttons (enabled in `tm1638` variants)
* `hdmi`: HDMI on-board output
* `lcd_480_272`: [40-pin 480x272 LCD display](https://www.adafruit.com/product/1591)
* `lcd_800_480`: [40-pin 800x480 LCD display](https://www.adafruit.com/product/1596)
* `yosys`: The same hardware, but uses [Yosys](https://github.com/YosysHQ/yosys) open source toolchain instead of a proprietary one.


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
