# BRS-100 manufacturer-port validation — 2026-10-11

Applies to the two `_by_codex` configurations with manufacturer GPIO ports.
The `_by_codex_alt` directories retain their separate historical validation
records. No hardware was programmed.

## Automated checks

`python3 scripts/tests/test_brs100.py` passed all five test groups across all
four configurations. After the final input-only CST adjustment, the pin-map
and manufacturer-constraint groups were rerun and passed.

- Twelve RGB-latency cases each inspect two complete frames: 480×272 with zero
  through three register stages, and 800×480 with zero or one stage, for each
  of the two wrapper styles.
- Thirty wrapper cases cover normal features, each feature alone, all disabled,
  the no-TM1638 override, and dedicated pin-mapping checks in both new wrappers.
  The mapping checks walk individual output bits, read microphone data, and
  exercise both directions and high-impedance release of TM1638/spare GPIOs.
- Header/package checks cover every physical GPIO. The SHA-256 of the preserved
  manufacturer file is pinned; all 47 `IO_LOC` lines must remain identical.
  Tests also check the fourteen permitted electrical-setting edits and LCD SDC
  port selection. The named GPIO bus retains the vendor's one-based numbering.
- Programmer dispatch is exercised with mocks; tests do not access USB.

`python3 scripts/tests/test_board_menu.py` passed all 22 tests, covering 116
configurations and 53 first-level groups. All four BRS-100 configurations group
under `brisbane_brs_100` and select Gowin.

README/report local links and SVG/PNG integrity were checked. Existing jumper
illustrations remain valid because the physical wiring is unchanged.

## Gowin checks — substitute device model only

The board Tcl still selects `GW1NR-LV9QN88PC7/I6`, device `GW1NR-9`, revision C.
Installed Gowin Education 1.9.11.03 rejects that exact part. Temporary projects
outside the repository use `GW1NR-LV9QN88PC6/I5` to check synthesis, CST/SDC
acceptance and placement/routing. This does not validate the exact board target;
no fallback was added and no temporary bitstream is supplied for programming.

The final new wrapper and constraints completed these four implementation checks:

| Lab | Resolution | Logic units | Registers | Worst setup slack, ns | Worst hold slack, ns | Setup / hold violations |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| color_stripes | 480×272 | 234 | 133 | 29.815 | 0.708 | 0 / 0 |
| color_stripes | 800×480 | 244 | 135 | 1.724 | 0.708 | 0 / 0 |
| microphone_monitor | 480×272 | 4353 | 1369 | 5.930 | 0.560 | 0 / 0 |
| microphone_monitor | 800×480 | 4360 | 1380 | 0.133 | 0.563 | 0 / 0 |

Logic units include LUTs and ALUs. The lab sources are
`labs/2_graphics/2_3_color_stripes` and `labs/3_music/3_11_microphone_monitor`.
Clock settings remain 27 MHz lab / 9 MHz pixel for 480×272 and 31 MHz for both
lab and pixel in 800×480.

The build checks caught two output-drive settings inappropriate for input-only
signals: flash MISO and GPIO 26 (microphone SD). Their vendor `DRIVE=8` attributes
were removed. The same error was reproduced on GPIOs 30–32 with an input-only
lab probe, so their DRIVE attributes were omitted as well. Their locations
and pulls were retained. The corrected input-only probe completed synthesis,
placement, routing and bitstream generation. Gowin also rejects Tcl
`set` variables in this SDC flow, so the two data-delay constraints explicitly
list their physical ports.

The preserved vendor electrical settings differ from `_alt`: most header pins
have pulldowns and explicit drive strength, and all four flash pins are present.
These differences are described in the README and HTML report.

## Remaining equipment checks

Build and review timing using the manufacturer's exact C7/I6 target. Verify
both LCD profiles against the actual panel's sampling edge, supply, connector,
setup/hold and backlight requirements. Check TM1638 through its level translator,
microphone capture, DAC audio, UART, buttons and LEDs on the assembled board.

The reported timing totals cover constrained paths. UART, TM1638 and I²S
external timing is not fully constrained, and jumper signal integrity is not
modeled. In particular, a passing substitute-model build is not a hardware
validation or a guarantee that every lab will meet timing.

Temporary evidence is under `/tmp/brs100-vendor-check/`; those files are local
and may be removed by the operating system. Source provenance and reproducible
simulation commands are included in this repository.
