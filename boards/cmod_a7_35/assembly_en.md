# Cmod A7-35T: breadboard assembly and first run

Board configuration: **cmod_a7_35** · Digilent Cmod A7-35T rev. B · prepared 16 November 2026.

[Русская инструкция](assembly_ru.html) · [Markdown](assembly_en.md) · [Implementation notes](README.md)

This configuration connects Tiny VGA through the Pmod socket, an INMP441 I²S microphone, a TM1638 LED&KEY module, and either of the two audio boards below. **TM1638 runs from 3.3 V and connects directly to the FPGA.** The nine accessory signals occupy consecutive DIP positions **26–34**. Physical DIP numbers, FPGA package balls, and Pmod contact numbers are different numbering systems; use the tables below.

The code and simulated signal timing have been checked. The graphics and microphone-monitor examples also passed Vivado 2026.1 synthesis, routing and bitstream generation, with positive setup/hold margins on constrained paths. The master XDC leaves external I/O delays unspecified. **Physical assembly, monitor compatibility and audio playback still require a board trial.**

## 1. Parts and physical arrangement

- Digilent **Cmod A7-35T**, not the 15T model; Micro-USB data cable and a computer with Vivado and Artix-7 device support.
- Breadboard space for the 48-pin module, short jumpers and a multimeter. Use two breadboards or a DIP breakout if the module hides the contact strips; both pin rows must remain accessible and electrically separate.
- **Tiny VGA Pmod by mole99**, with two bits per colour, plus a VGA cable and monitor. A two-Pmod Digilent Pmod VGA has a different interface and is not a direct substitute.
- **INMP441** breakout with VDD, GND, SCK, WS, SD and L/R labels.
- Standard **TM1638 LED&KEY** board with eight buttons, eight LEDs and eight digits, operated at **3.3 V**. Its supply and signal pull-ups all use 3.3 V; no level translator is fitted.
- A regulated **3.3 V accessory supply** for TM1638 and INMP441, for example a low-dropout 3.3 V regulator breakout fed from the USB-derived VU rail. Choose a regulator whose input range and dropout suit the measured VU voltage and whose current and thermal ratings cover the display at maximum brightness plus the microphone; use its specified input/output capacitors. Do not assume every “AMS1117” module will regulate with every USB cable.
- One DAC: **WeAct I2S Earphone Module PCM5100A Stereo HP AMP 32 Ω 160 mW**, or **GY-PCM5102 PCM5102A pHAT-format I²S DAC**. Use headphones for the WeAct headphone jack; use an amplifier or powered speakers for the GY board’s line output.

Place the Cmod across separate breadboard contact groups. Identify pin 1 from the board marking and the [Digilent DIP drawing, Figure 8.1](https://digilent.com/reference/_media/reference/programmable-logic/cmod-a7/cmod_a7_rm.pdf#page=9), then locate **24 = VU**, **25 = GND**, and **26–34**. Use the printed numbers, not a guessed left/right orientation: turning the board over mirrors the view. Check continuity before plugging in USB.

Put the TM1638 cable near pins 26–28, the microphone near 29–31, and the DAC near 32–34. Keep the microphone opening unobstructed and away from speakers. The drawing is a connection map, not a scale drawing of breadboard holes.

![Connection map: Cmod A7, Tiny VGA, direct 3.3 V TM1638, INMP441 and DAC](wiring.svg)

## 2. Power wiring — complete this before signal wiring

1. Unplug USB and all supplies before moving wires. Leave the analog DIP pins 15/16, SRAM and flash connections unused.
2. Use USB as the board’s sole power source for the initial build. Digilent documents **VU, DIP 24**, as USB-derived power when USB is connected; it is approximately 5 V, with a diode drop. **DIP 25 is ground.** Never attach an external supply to VU while USB is connected.
3. Connect pin 25 to the common ground rail. Connect every accessory ground to that rail. Bridge split breadboard rails only after checking them with a meter.
4. Feed the DAC’s verified 5 V/VIN input and the **input of the 3.3 V accessory regulator** from the USB-derived VU rail. Allow for the combined FPGA, display and audio current: a connector is not an unlimited power supply. If the rails sag or the board disconnects, use a suitable powered USB source or a separate regulated accessory supply. With a separate accessory supply, disconnect the VU-to-accessory feed and keep only the grounds common.
5. Connect the regulator’s **3.3 V output to TM1638 VCC and INMP441 VDD**. The regulator must maintain 3.3 V with the display at maximum brightness. Do not connect this regulator output to the Cmod’s Pmod 3.3 V outputs; Tiny VGA obtains its power directly through the Pmod socket.
6. Keep every TM1638 signal pull-up connected to the module’s **3.3 V VCC**. Wire DIO, CLK and STB directly to DIP 26, 27 and 28 respectively, using short wires. Keep TM1638 powered from 3.3 V with this direct connection; do not connect its VCC or pull-ups to VU/5 V.
7. Measure VU, accessory 3.3 V and the grounds before fitting the modules, then check the 3.3 V rail again with the display lit. No FPGA signal pin supplies power, and no 5 V signal is wired directly to the FPGA.

References: [Digilent power and DIP documentation](https://digilent.com/reference/_media/reference/programmable-logic/cmod-a7/cmod_a7_rm.pdf). [TM1638 library authors report successful 3.3 V supply and logic operation](https://github.com/bitbank2/tm1638). This assembly uses that arrangement; check the buttons and display on your module during bring-up. Titan’s [TM1638 data sheet](https://futuranet.it/futurashop/image/catalog/data/Download/TM1638_V1.3_EN.pdf#page=15) characterizes electrical behavior at 4.5–5.5 V, so it does not guarantee the 3.3 V operating point.

## 3. Compact accessory pin map

The names in the XDC are retained verbatim. All functional mapping is inside `board_specific_top.sv`.

| DIP position | XDC/top port | FPGA ball | Function | Wire destination |
| --- | --- | --- | --- | --- |
| 26 | pio26 | R3 | TM1638 bidirectional data | TM1638 DIO, direct 3.3 V logic |
| 27 | pio27 | T3 | TM1638 clock | TM1638 CLK, direct 3.3 V logic |
| 28 | pio28 | R2 | TM1638 strobe | TM1638 STB, direct 3.3 V logic |
| 29 | pio29 | T1 | Microphone bit clock | INMP441 SCK |
| 30 | pio30 | T2 | Microphone word select | INMP441 WS |
| 31 | pio31 | U1 | Microphone data input | INMP441 SD |
| 32 | pio32 | W2 | DAC bit clock | WeAct BCK or GY BCK |
| 33 | pio33 | V2 | DAC data output | WeAct DIN or GY DIN |
| 34 | pio34 | W3 | DAC word clock | WeAct WS or GY LCK/LRCK |

Connect **INMP441 L/R to ground** to select the left channel. Power it from the accessory **3.3 V** rail, never VU. Keep its SCK and SD labels distinct: SCK is a clock from the FPGA, SD is data back to the FPGA. The [INMP441 data sheet](https://invensense.tdk.com/wp-content/uploads/2015/02/INMP441.pdf) describes a 24-bit I²S output; the wrapper receives the left-channel signed sample.

With the common 100 MHz clock, the existing microphone receiver produces approximately **3.125 MHz SCK and 48.828125 kHz WS**. These are the expected measurement values, not exactly 3.072 MHz and 48 kHz.

## 4. Tiny VGA on the Pmod socket

Fit Tiny VGA with its numbered contacts aligned to Cmod **JA**. Contacts 5/11 are ground and 6/12 are 3.3 V; verify the connector orientation before applying power. Use a straight-through Pmod extension only if necessary.

| Physical JA contact | XDC/top port | FPGA ball | Tiny VGA signal |
| --- | --- | --- | --- |
| 1 | ja[0] | G17 | R1, red MSB |
| 2 | ja[1] | G19 | G1, green MSB |
| 3 | ja[2] | N18 | B1, blue MSB |
| 4 | ja[3] | L18 | VS, vertical sync |
| 7 | ja[4] | H17 | R0, red LSB |
| 8 | ja[5] | H19 | G0, green LSB |
| 9 | ja[6] | J19 | B0, blue LSB |
| 10 | ja[7] | K18 | HS, horizontal sync |

This is **64-colour RGB222**. The wrapper forces RGB black during blanking. Timing uses 640 × 480 visible pixels, 800 × 525 total, a 25 MHz pixel rate, 31.25 kHz horizontal rate and about **59.524 Hz** vertical refresh. This follows the repository’s existing 25 MHz VGA convention, rather than the nominal 25.175 MHz VGA clock; verify acceptance by your monitor.

The FPGA’s MMCM converts the onboard 12 MHz oscillator to 100 MHz. No rewrite of `peripherals/vga.sv` is necessary. [Tiny VGA’s designer pinout](https://github.com/mole99/tiny-vga#tiny-vga-pinout) is the mapping authority.

## 5. DAC option A: WeAct PCM5100A earphone board

The [official WeAct V1.0 schematic](https://github.com/WeActStudio/WeActStudio.I2SEarphoneModuleV1/blob/master/Hardware/WeAct-I2SEarphoneModuleV1_V10%20SchDoc.pdf) identifies a seven-contact header. Match the labels on your board; a photograph taken from the reverse side changes apparent order.

| WeAct P1 contact | Label | Connection |
| --- | --- | --- |
| 1 | VCC | Accessory 5 V/VU rail, subject to supply budget |
| 2 | GND | Common ground |
| 3 | /SD | Leave open: the V1.0 schematic pulls CTRL up to 3.3 V; grounding it mutes/shuts down |
| 4 | MCLK / MC | Ground for three-wire I²S operation |
| 5 | BCK / BC | Cmod DIP 32 |
| 6 | DIN / DI | Cmod DIP 33 |
| 7 | WS | Cmod DIP 34 |

The schematic contains a 3.3 V regulator, PCM5100A and an HT97226 headphone amplifier. The factory circuit selects I²S; leave the de-emphasis bridge in its default off state. Start with a quiet signal and connect headphones to the jack. The `/SD` control is **not** the INMP441 `SD` data signal. Do not connect `/SD` to the microphone or tie it to 5 V.

## 6. DAC option B: GY-PCM5102 / PCM5102A pHAT-format board

GY boards are sold in multiple PCB layouts. The sales name alone does not identify a unique header order or solder-bridge numbering. Use the printed **signal labels** below and verify the regulator/jumper arrangement on the actual module; do not copy the WeAct contact numbers.

| GY board label | Connection or setting |
| --- | --- |
| VIN / 5V | Accessory 5 V rail only if this is the module’s regulated input |
| 3V3, if present | Use only according to that PCB’s documented supply circuit; never apply 5 V to this label |
| GND | Common ground |
| BCK / BCLK | Cmod DIP 32 |
| DIN / DATA | Cmod DIP 33 |
| LCK / LRCK / WS | Cmod DIP 34 |
| SCK / MCLK | Ground for the DAC’s BCK-derived internal PLL |
| XSMT / XMT | High at the DAC’s 3.3 V logic rail to unmute; confirm any existing pull-up |
| FMT | Low: I²S |
| FLT | Low: normal-latency filter |
| DEMP | Low: de-emphasis off |

Inspect existing solder bridges before adding wires; do not short an existing high strap to ground. The exact GY PCB revision has not been supplied, so bridge numbers and physical header order are intentionally not guessed. The electrical settings above come from the [TI PCM510xA data sheet](https://www.ti.com/lit/ds/symlink/pcm5102a.pdf).

The GY jack or L/R pads are normally **line-level outputs**. Connect them to powered speakers or a separate headphone amplifier. A PCM5102A alone is not a 32 Ω headphone driver; TI specifies line loads down to 1 kΩ. Never connect the two output channels together.

Both options use the same FPGA image and three data/clock wires. The existing serializer sends the mono 16-bit `sound` value in both channels of 32-bit I²S slots, one bit after each LRCK transition. Expected BCK is **3.125 MHz**, LRCK **48.828125 kHz**, with **64 BCK periods per stereo frame**. No external MCLK wire is required; the unused FPGA MCLK output stays internal.

## 7. Buttons, display, GPIO and reset

- **BTN0** resets the MMCM and the design. Reset also asserts when clock lock is lost; it releases after three system-clock edges following lock. If lock is lost, press and release BTN0 to restart the clock manager.
- **BTN1** is the onboard lab key. In the default duplicate mode it is ORed into `key[0]`; TM1638 S1–S8 supply `key[0]`–`key[7]`.
- There are no slide switches. The same TM1638 buttons supply `sw[0]`–`sw[7]` as **momentary inputs**, not latched toggles. Labs requiring sustained switch combinations need the buttons held or an explicitly adapted input scheme.
- The two onboard LEDs duplicate the lowest two lab LED bits. The TM1638 shows all eight lab LED bits and eight digits. The common concatenation macros are also supported; their alternate key/LED ordering is described in the implementation notes.
- The active-low RGB LED is red while reset is asserted and green while running; blue is off. It is a clock/reset indicator, not a proof that every peripheral works.
- Generic `gpio[0]`–`gpio[7]` map to DIP **1–8**. These pins are separate from accessory pins 26–34; leave them unconnected unless the chosen lab calls for them.
- The onboard USB-UART uses `uart_txd_in` toward the FPGA and `uart_rxd_out` toward the PC. No external UART wiring is needed.

## 8. Build and bring-up

From a lab directory, run the normal board selector and choose **cmod_a7_35**. The setup script dispatches this configuration to Vivado and targets **xc7a35tcpg236-1**, hardware device **xc7a35t_0**.

```bash
cd labs/2_graphics/2_1_rectangle_ellipse_parabola
./06_choose_another_fpga_board.bash
./03_synthesize_for_fpga.bash
```

The repository’s synthesis wrapper proceeds to configuration after a successful build. Use a powered, checked assembly and read the tool output. For a later programming run, use `./04_configure_fpga.bash`; this performs volatile FPGA programming, not a new flash-programming procedure.

1. First connect only the Cmod and USB. Confirm that Vivado detects the **35T** part. Inspect clock, timing and DRC reports after the build: the 12 MHz input and approximately 100 MHz MMCM output must be present, with no unexplained timing or pin-assignment errors.
2. With power removed, add Tiny VGA. Run the graphics lab and check geometry, colour ordering and blanking. A working VGA image is the first clock/video check.
3. Add TM1638 with **VCC = 3.3 V**, common ground, and direct DIO/CLK/STB connections to DIP 26/27/28. In `lab_specific_board_config.svh`, enable `INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE` when the lab needs the display/keys. Check each button, LED and digit, and verify the 3.3 V supply under display load before adding audio.
4. Add the INMP441. Enable `INSTANTIATE_MICROPHONE_INTERFACE_MODULE`; run `labs/3_music/3_0_oscilloscope` and speak or clap near the microphone. Check for a changing waveform, not just an active clock.
5. Fit **one** DAC option. Enable `INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE`. Run `labs/3_music/3_3_note_synthesizer` to check a generated tone, then `labs/3_music/3_11_microphone_monitor` for the microphone-to-DAC route. Keep the microphone away from the output speaker to avoid feedback.
6. If a peripheral macro is disabled, its clocks/data are held inactive and its input value is zero. This is intentional; changing wiring cannot enable a compiled-out peripheral. Graphics also needs `INSTANTIATE_GRAPHICS_INTERFACE_MODULE`.

## 9. Troubleshooting

| Symptom | First checks |
| --- | --- |
| Red RGB LED stays on | BTN0 not held; 12 MHz oscillator, MMCM lock and power stable; correct part selected |
| Monitor reports no signal | Tiny VGA orientation; JA4 = VS and JA10 = HS; graphics macro; measured sync rates; monitor accepts the 25 MHz convention |
| Image has incorrect colours or borders | Use the R1/R0 table, not an 8-colour Pmod map; inspect blanking and colour-bit order |
| TM1638 digits work but keys do not | DIO connects directly to DIP 26; pull-ups use 3.3 V; common ground; correct LED&KEY module variant |
| TM1638 display is dim or unstable | Measure 3.3 V at module VCC under load; check regulator current/thermal capacity, short power leads and brightness setting |
| Microphone is silent | VDD = 3.3 V; L/R = GND; SD/SCK not swapped; microphone macro enabled |
| DAC clocks exist but no sound | Unmute and I²S settings; MCLK/SCK grounded; correct output load; nonzero lab sound samples |
| USB disconnects when display/audio starts | Supply/cable voltage drop or excessive combined current; stop and check the power distribution |

## 10. Sources and reproducibility

- [Digilent Cmod A7 reference manual](https://digilent.com/reference/_media/reference/programmable-logic/cmod-a7/cmod_a7_rm.pdf): board, power and connector details.
- [Digilent master XDC, pinned revision](https://github.com/Digilent/digilent-xdc/blob/c8644a9fe31cc803789643124545d56b3bef4600/Cmod-A7-Master.xdc): original pin definitions. [Local unchanged copy](reference/Cmod-A7-Master.xdc) and [provenance](reference/source.json).
- [Tiny VGA designer repository](https://github.com/mole99/tiny-vga): RGB222 Pmod assignment.
- [WeAct manufacturer repository](https://github.com/WeActStudio/WeActStudio.I2SEarphoneModuleV1): V1.0 schematic and header.
- [TM1638 3.3 V operation report](https://github.com/bitbank2/tm1638) and [Titan TM1638 data sheet](https://futuranet.it/futurashop/image/catalog/data/Download/TM1638_V1.3_EN.pdf): practical operation and published electrical specifications.
- [TI PCM510xA data sheet](https://www.ti.com/lit/ds/symlink/pcm5102a.pdf), [INMP441 data sheet](https://invensense.tdk.com/wp-content/uploads/2015/02/INMP441.pdf).
- [AMD MMCME2_BASE documentation](https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/MMCME2_BASE): clock primitive and lock/reset behavior.

Run the board-specific automated checks from the repository root:

```bash
python3 scripts/tests/test_cmod_a7_35.py
python3 scripts/tests/test_board_menu.py
```

The functional tests use a test-only clock model. They check pin preservation and coverage, existing-lab elaboration, a complete VGA raster and blanking, microphone data, I²S serialization, UART/GPIO mapping and reset. They do not simulate analog levels, breadboard signal integrity, monitor acceptance or the actual MMCM lock dynamics.

## Appendix: original task and Russian translation

### Original English prompt / Английский оригинал

```text
# Task

Create a new branch of basics_graphics_music called claude_cmod_a7 starting from main.
The branch should be called claude_cmod_a7 is you are claude and codex_cmod_a7 is you are codex.

Read board implementations:

* alinx_ax7035b
* arty_a7_100
* arty_a7_100_pmod_mic3
* arty_a7_35
* arty_a7_35_pmod_mic3
* basys3
* nexys4
* nexys4_ddr
* nexys_a7  
* nexys_a7_100
* nexys_a7_50 
* zybo_z7
* zzz_postponed_and_retired/cmod_a7

Specifically the files:

* board_specific.tcl
* board_specific_top.sv
* board_specific.xdc

Create a new board implementation cmod_a7_35 for Digilent Cmod A7-35T.

The existing zzz_postponed_and_retired/cmod_a7 is wrong.

Copy the following file into boards/cmod_a7_35/board_specific.xdc

https://github.com/Digilent/digilent-xdc/blob/master/Cmod-A7-Master.xdc

Uncomment only the necessary pins. Do not modify any pin names or definitions - only uncomment the existing.

All name mapping should be inside board_specific_top.sv.

Use Pmod socket to accomodate TinyVGA.

If necessary, write your own VGA interface module if basics-graphics-music/peripherals/vga.sv is not suitable.

Or alternatively propose a modification of basics-graphics-music/peripherals/vga.sv to accomodate the clock frequency.

Update the relevant bash scripts in scripts/steps

Create .md and HTML files with an instruction on how to assemble a breadboard with this board, microphone and either of the following DAC modules:

* WeAct I2S Earphone Module PCM5100A Stereo HP AMP 32Ω 160mW DAC Decoder Audio Board

* Interface I2S PCM5102A DAC Decoder GY-PCM5102 I2S Player Module For Raspberry Pi PHAT Format Board Digital PCM5102 Audio Board

When planning what pins to use for the TM1638, microphone and sound DAC connection, make them compact and easy to assemple.

Add this prompt as an appendix to .md and HTML files.

In addition to the instriction in English create an instruction in Russian (also .md and .html). In prompt appendix put both the original prompt in English and its transaction to Russian.
```

### Russian translation / Русский перевод

```text
# Задание

Создайте новую ветку basics_graphics_music с именем claude_cmod_a7, начиная с main.
Ветка должна называться claude_cmod_a7, если вы Claude, и codex_cmod_a7, если вы Codex.

Изучите реализации плат:

* alinx_ax7035b
* arty_a7_100
* arty_a7_100_pmod_mic3
* arty_a7_35
* arty_a7_35_pmod_mic3
* basys3
* nexys4
* nexys4_ddr
* nexys_a7
* nexys_a7_100
* nexys_a7_50
* zybo_z7
* zzz_postponed_and_retired/cmod_a7

В частности, файлы:

* board_specific.tcl
* board_specific_top.sv
* board_specific.xdc

Создайте новую реализацию платы cmod_a7_35 для Digilent Cmod A7-35T.

Существующая реализация zzz_postponed_and_retired/cmod_a7 неправильная.

Скопируйте следующий файл в boards/cmod_a7_35/board_specific.xdc:

https://github.com/Digilent/digilent-xdc/blob/master/Cmod-A7-Master.xdc

Раскомментируйте только необходимые выводы. Не изменяйте имена или определения выводов — только раскомментируйте существующие строки.

Все сопоставления имён должны находиться в board_specific_top.sv.

Используйте разъём Pmod для подключения TinyVGA.

При необходимости напишите собственный модуль интерфейса VGA, если basics-graphics-music/peripherals/vga.sv не подходит.

Либо предложите изменение basics-graphics-music/peripherals/vga.sv с учётом тактовой частоты.

Обновите соответствующие Bash-скрипты в scripts/steps.

Создайте файлы .md и HTML с инструкцией по сборке на макетной плате схемы с этой платой, микрофоном и одним из следующих модулей ЦАП:

* WeAct I2S Earphone Module PCM5100A Stereo HP AMP 32Ω 160mW DAC Decoder Audio Board

* Interface I2S PCM5102A DAC Decoder GY-PCM5102 I2S Player Module For Raspberry Pi PHAT Format Board Digital PCM5102 Audio Board

Планируя использование выводов для TM1638, микрофона и звукового ЦАП, сделайте соединения компактными и удобными для сборки.

Добавьте этот запрос в качестве приложения к файлам .md и HTML.

Кроме английской инструкции создайте русскую инструкцию (также .md и .html). В приложении с запросом приведите и английский оригинал, и его перевод на русский язык.
```

### Microphone clarification / Уточнение микрофона

The user selected: “INMP441 I²S microphone (recommended)”.

Пользователь выбрал: «Микрофон INMP441 с интерфейсом I²S (рекомендуется)».
