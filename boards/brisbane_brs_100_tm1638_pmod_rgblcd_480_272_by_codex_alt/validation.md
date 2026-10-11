# BRS-100 validation — 2026-10-10

Applies to both resolution configurations. No hardware was programmed.

## Automated checks

- `python3 scripts/tests/test_brs100.py`: passed all four test groups.
  Six RGB-latency cases each inspect two complete frames: 480×272 with zero
  through three register stages, and 800×480 with zero or one stage.
  Fourteen wrapper cases cover normal features, each feature alone, all features
  disabled, and the explicit no-TM1638 override for both configurations.
  Pin-map checks and mocked calls to both programmer backends also pass.
- `python3 scripts/tests/test_board_menu.py`: 22 tests pass, covering 114 board
  configurations and 53 first-level groups. Both new configurations belong to
  `brisbane_brs_100` and select the Gowin toolchain.
- Bash syntax checks pass. README local links, SVG XML, PNG integrity and
  matching pin constraints between the two configurations were checked.
  The wiring drawings were also inspected visually.

## Gowin implementation checks — substitute device model only

The official BRS-100 target in the board source files is
`GW1NR-LV9QN88PC7/I6`, device `GW1NR-9`, revision C. Gowin Education 1.9.11.03
on this host returns `can't find device` for that part. No automatic fallback
was added to the board files.

For additional RTL, pin and timing checks, temporary projects outside the
repository used the available `GW1NR-LV9QN88PC6/I5` model with revision C.
The same source files, CST and SDC were used. The standard BGM source list
was generated, excluding a stale generated netlist in an existing lab's
ignored `run/` directory. These checks use Gowin Education 1.9.11.03.
**They do not establish C7/I6 hardware compatibility or replace an exact-target
build. Do not treat those temporary bitstreams as BRS-100 release artifacts.**

| Lab | Resolution | Logic units | Registers | Worst setup slack, ns | Worst hold slack, ns | Setup / hold violations |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| color_stripes | 480×272 | 234 | 133 | 29.815 | 0.708 | 0 / 0 |
| color_stripes | 800×480 | 244 | 135 | 1.724 | 0.708 | 0 / 0 |
| microphone_monitor | 480×272 | 4353 | 1369 | 5.935 | 0.560 | 0 / 0 |
| microphone_monitor | 800×480 | 4360 | 1380 | 0.133 | 0.563 | 0 / 0 |

The tested labs are `labs/2_graphics/2_3_color_stripes` and
`labs/3_music/3_11_microphone_monitor`. Logic units include LUTs and ALUs.
The four checks completed synthesis, placement, routing and bitstream generation.
No generated bitstream is included in either board directory.

The 800×480 configuration uses 31 MHz rather than 32 MHz to give the registered
RGB path in the microphone/spectrum example positive timing margin in this
model. The 480×272 configuration uses 27 MHz lab / 9 MHz pixel clocks.
Registered coordinates keep raster arithmetic out of paths into the lab;
`syn_preserve` on RGB output registers prevents identical white/color bits
from collapsing into a single register with excessive output loading.

The LCD output constraints assume maximum panel setup/hold requirements of
10 ns for 480×272 and 8 ns for 800×480, plus 2 ns for wire skew. Satisfying these
constraints does not validate the actual panel or jumper signal integrity.
UART, TM1638 and I²S external timing remains incomplete; the timing totals above
cover the constrained paths, not every off-board protocol.

## Remaining checks on the intended equipment

1. Build using the manufacturer's exact C7/I6 part and inspect timing reports
   for the selected lab. Labs with deeper RGB pipelines need explicit alignment.
2. Confirm the particular 40-pin LCD's supply, pixel sampling edge, timing,
   FPC orientation and backlight requirements match the adapter/profile.
3. Check LCD frame edges and color bits, TM1638 keys/display through the level
   translator, both reset buttons, USB UART, microphone samples and DAC output.
4. Verify power-up behavior, USB current budget, jumper length and logic levels.

Sources for the pin mapping, electrical assumptions and timing profiles are
linked in each README. The prompt and resolution clarification are saved in
`codex_prompt.txt` in each configuration directory.
