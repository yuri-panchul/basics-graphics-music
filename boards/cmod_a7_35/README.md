# Cmod A7-35T

- [English assembly guide](assembly_en.md) · [HTML](assembly_en.html)
- [Инструкция по сборке на русском](assembly_ru.md) · [HTML](assembly_ru.html)

Target: `xc7a35tcpg236-1`, hardware-manager device `xc7a35t_0`.
The configuration was added on branch `codex_cmod_a7`, based on main
`905cba6f`. The retired 15T wrapper is not reused.

## Implementation

The master XDC is copied from Digilent revision
`c8644a9fe31cc803789643124545d56b3bef4600`. Only the first comment marker on
required lines was removed. All remaining bytes, port names, package pins,
I/O standards and the 83.33 ns clock constraint are unchanged. The original
is preserved under `reference/` with its SHA-256 and retrieval date. There
are 35 constrained scalar pins, including the clock, UART, local LEDs/buttons,
eight Pmod signals, eight generic GPIOs, and nine accessory signals.

The 12 MHz oscillator drives `MMCME2_BASE`: divide 1, multiply 50, divide 6.
Its 600 MHz VCO produces a 100 MHz system clock through a BUFG, with a BUFG
feedback path. The existing VGA module divides the system clock by four;
the audio modules operate in their existing 100 MHz mode. Shared peripherals
are unchanged. The MMCM is always a hardware primitive in production; only
the test fixture provides a behavioral clock model.

BTN0 resets the MMCM and asynchronously asserts the application reset; loss
of lock also asserts reset. Three clock edges release reset after lock.
BTN1 has a two-register synchronizer. The RGB LED uses the board's active-low
polarity, while the two single LEDs use active-high polarity.

The default video interface is 640×480, 25 MHz RGB222 with negative syncs and
explicit RGB blanking. This gives 59.524 Hz rather than exact 60 Hz. Full
blanking counters use 10-bit vertical position; the lab gets its usual
9-bit visible coordinate. Tiny VGA uses JA4 for VS and JA10 for HS.

Physical mappings are entirely inside `board_specific_top.sv`:

- `gpio[0..7]` → pio1..pio8.
- TM1638 DIO/CLK/STB → pio26/27/28 directly; module VCC and all signal
  pull-ups use the accessory 3.3 V supply.
- INMP441 SCK/WS/SD → pio29/30/31; L/R wired to ground.
- DAC BCK/DIN/LRCK → pio32/33/34; DAC MCLK/SCK wired to ground.
- USB RX/TX retain Digilent's `uart_txd_in` / `uart_rxd_out` port names.

The accessory 3.3 V regulator powers both TM1638 and INMP441 and must be sized
for the display load plus the microphone. TM1638 uses no level translator.
Its supply and pull-ups must remain at 3.3 V for the direct FPGA connection.
The DAC retains its own documented supply arrangement. The guides cite
reported 3.3 V TM1638 operation and distinguish it from Titan's electrical
characterization at 4.5–5.5 V; check the actual module during bring-up.

The wrapper honors the common `INSTANTIATE_*` macros for video, TM1638,
microphone and audio. Disabled outputs have explicit inactive values; the
disabled TM1638 DIO is high-impedance. The default TM1638 is the eight-key
LED&KEY variant. Split-DIO mode and the first eight keys of the HCW132 variant
also elaborate, but the assembly instructions describe the standard board.

## Key and LED ordering

| Mode | Lab keys, low to high | Lab LEDs, low to high |
| --- | --- | --- |
| Default / DUPLICATE_TM1638_SIGNALS_WITH_REGULAR | TM keys 0–7, with BTN1 ORed into bit 0 | TM LEDs 0–7; onboard LEDs duplicate bits 0/1 |
| CONCAT_TM1638_SIGNALS_AND_REGULAR | BTN1, then TM keys 0–7 | Onboard LEDs 0/1, then TM LEDs 0–7 |
| CONCAT_REGULAR_SIGNALS_AND_TM1638 | TM keys 0–7, then BTN1 | TM LEDs 0–7, then onboard LEDs 0/1 |

Digits always come from TM1638. `sw[0..7]` are the raw momentary TM keys,
independent of concatenation mode. There are no physical slide switches.

## Reference implementations reviewed

The Tcl, top-level HDL and XDC files were inspected for `alinx_ax7035b`,
`arty_a7_100`, `arty_a7_100_pmod_mic3`, `arty_a7_35`,
`arty_a7_35_pmod_mic3`, `basys3`, `nexys4`, `nexys4_ddr`, `nexys_a7`,
`nexys_a7_100`, `nexys_a7_50`, `zybo_z7`, and
`zzz_postponed_and_retired/cmod_a7`. The Arty and Nexys aliases reuse their
family's common wrappers. Relevant patterns were the common lab interface,
TM1638 concatenation, INMP441/I²S blocks, VGA blanking, and Vivado part/device
selection. The old Cmod wrapper targets the 15T, has undeclared signals from
other boards, and has no working VGA integration.

## Validation

From the repository root:

```bash
python3 scripts/tests/test_cmod_a7_35.py
python3 scripts/tests/test_board_menu.py
```

The first command verifies XDC byte preservation, exact top-port constraint
coverage, package-pin uniqueness, basic and representative other labs, TM1638
configuration variants, reset/lock handling, GPIO/UART direction, a complete
800×525 raster with 640×480 visible pixels, sync widths, blanking, microphone
samples and stereo I²S framing. The second exercises real board selection
and toolchain dispatch without modifying a user's saved selection.

Vivado 2026.1 successfully built both examples outside the execution
sandbox; the sandbox had prevented license detection. Results on 2026-11-16:

| Lab | Setup WNS | Hold WHS | LUTs | Registers | Bitstream |
| --- | --- | --- | --- | --- | --- |
| `2_graphics/2_1_rectangle_ellipse_parabola` | +5.220 ns | +0.109 ns | 206 | 115 | Generated |
| `3_music/3_11_microphone_monitor` | +2.351 ns | +0.034 ns | 2011 | 1356 | Generated |

Both builds have zero setup/hold failing endpoints and zero DRC errors.
DRC warnings remain: `CFGBVS-1` because the master XDC does not specify
configuration-bank voltage properties, plus DSP pipelining recommendations
in the graphics lab. Neither warning was suppressed. The real 12 MHz input,
MMCM feedback and nominal 100 MHz output are recognized, with no unclocked
registers or unconstrained internal endpoints. External I/O delays are not
specified by the preserved Digilent master XDC, so passing constrained-path
timing does not establish external-interface timing closure. Physical board
testing remains outstanding.

The TM1638 3.3 V wiring revision changes the assembly documentation and HDL
comments only. The FPGA logic and LVCMOS33 pin constraints are identical to
those used for the builds above; the existing bitstreams remain applicable.

The five board regression tests passed, including elaboration of 17 labs
and five TM1638 configurations. All 22 board-menu tests passed across 114
configurations. Both HTML guides passed desktop (1440 px) and mobile (390 px)
layout checks; their local links, diagram and bilingual prompt appendices
were checked.

A separate batch driver builds without programming the FPGA. From a fresh
output directory, with Vivado on PATH, substitute the repository location:

```bash
vivado -mode batch -source /path/to/basics-graphics-music/scripts/tests/build_cmod_a7_35.tcl \
    -tclargs labs/3_music/3_11_microphone_monitor
```

Omit `-tclargs` and the lab path to build the rectangle/ellipse/parabola example.
The driver writes timing, clock, utilization and DRC reports, a routed checkpoint
and `cmod_a7_35.bit`. It stops before bitstream generation if constrained setup
or hold timing fails. Read the report's missing I/O-delay checks as well.

## Documentation maintenance

The Markdown guides are the editable source. Each includes the verbatim task
prompt and its Russian translation. Rebuild the two HTML files with:

```bash
python3 boards/cmod_a7_35/build_docs.py
```

The SVG connection map is shared by both editions. The GY sales description
does not identify a unique PCB revision: its guide specifies electrical
signal names and settings without inventing header or jumper numbers.
