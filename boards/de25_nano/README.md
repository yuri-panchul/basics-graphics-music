# Terasic DE25-Nano

Based on `de23_lite`, for the Agilex 5 `A5EB013BB23BE4SCS`.
Use **Quartus Prime Pro** with this exact device installed. Tested with
**26.1.1 Pro**; the minimum supported release has not been established.
USB-Blaster III is built into the board. Connect its USB-C port with a data
cable, power the board, and install the driver supplied with Quartus Pro.
Check the connected JTAG chain before programming; the tested board used index 1.

## Connections

| Resource | Lab connection |
| --- | --- |
| Clock | `CLOCK1_50`, 50 MHz |
| Reset | `SW[3]`, active high; asynchronous assertion, two-clock synchronous release |
| Buttons | `key[1:0] = ~KEY[1:0]`; pressed means 1 |
| Switches | `sw[2:0] = SW[2:0]`; towards the board centre means 1 |
| LEDs | `LEDR[7:0] = ~led[7:0]`; logical 1 lights the corresponding LED |
| General GPIO | `gpio[35:0]` connects to `GPIO_1[35:0]` |
| Accessory GPIO | `GPIO_0`, separate from general lab GPIO |
| HDMI | ADV7513, RGB888, 640 x 480 with a 25 MHz pixel clock |
| Seven-segment display | No onboard display; eight logical digits for an optional TM1638 |

The mux lab uses SW2 as select and SW1/SW0 as data. SW3 is reserved for reset.
HDMI follows `INSTANTIATE_GRAPHICS_INTERFACE_MODULE`; HDMI audio is disabled.
Without accessories, microphone samples are zero and UART RX is idle-high.
HPS, SDRAM, LPDDR4, ADC and MIPI are outside this profile.

## Optional accessories

Enable only connected modules with these defines in the lab's
`lab_specific_board_config.svh`. The generic course peripheral flags do not
implicitly enable external DE25-Nano accessories.

| Define | Signals on `GPIO_0` | Physical header pins |
| --- | --- | --- |
| `DE25_NANO_USE_TM1638` | STB `[27]`, CLK `[29]`, DIO `[31]` | 32, 34, 36 |
| `DE25_NANO_USE_INMP441` | L/R `[0]`, WS `[2]`, SCK `[4]`, SD `[5]` | 1, 3, 5, 6 |
| `DE25_NANO_USE_I2S_AUDIO` | MCLK `[17]`, BCLK `[15]`, LRCLK `[11]`, DATA `[13]` | 20, 18, 14, 16 |
| `DE25_NANO_USE_UART` | FPGA RX `[6]`, FPGA TX `[7]` | 7, 8 |

Use 3.3 V logic and a common ground. GPIO_0 header pin 29 supplies 3.3 V;
pins 12 and 30 are GND. Follow the Terasic header orientation diagram.
TM1638 adds eight logical keys, ORed with the onboard keys, and duplicates the
LEDs. With TM1638 enabled the mux lab uses keys instead of switches.
GPIO_0[31] has a weak pull-up; unused GPIO output drivers are disabled.

## Implementation notes

The Reset Release IP comes from Terasic's HDMI example, with its device
metadata updated to `A5EB013BB23BE4SCS`. The project generator stages `.ip`
files under the run directory so generated RTL does not modify board sources.

Pin assignments match the Rev A/B v1.0.0 `Golden_top/golden_top.qsf` files.
**HDMI_TX_CLK uses 1.1 V**, as specified by both vendor QSFs; the manual's
3.3 V table entry conflicts with them. Switches and LEDs also use 1.1 V.
The HDMI I2C helpers are adapted from DE23-Lite and the Terasic HDMI example.

The SDC assumes the fixed 50 MHz input and 25 MHz pixel clock. Its conservative
625 Hz model of the 1 Hz slow clock avoids Quartus's maximum-period limit;
the actual slow clock remains 1 Hz. HDMI output delays use the ADV7513's
1.8 ns setup and 1.3 ns hold requirements with zero assumed PCB skew.
Actual PCB skew and synchronous external GPIO timing require additional
constraints; GPIO and low-rate I2C paths are excepted in this profile.

## Validation

Onboard switches, buttons, LEDs, reset and HDMI were tested on a DE25-Nano
(box label 0B) on 2026-10-16. HDMI reconnection and cold power-on followed by
JTAG reconfiguration passed. External accessories were simulated and compiled,
but have not been physically verified. Autonomous flash boot was not tested.

Run the regression tests with Python, Bash and Icarus Verilog available:

```sh
python3 scripts/tests/test_de25_nano.py
python3 scripts/tests/test_quartus_discovery.py
python3 scripts/tests/test_board_menu.py
```

## References

- [Terasic DE25-Nano resources](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1384&PartNo=4)
- [Rev B v1.0.0 resource package](https://dl2.terasic.com/resources/de25-nano/DE25-Nano_revB_v.1.0.0_ResourcePackage.zip)
- [Agilex 5 Reset Release IP](https://docs.altera.com/r/docs/813773/25.3.1/device-configuration-user-guide-agilextm-5-fpgas-and-socs/including-the-reset-release-ip-in-your-design)
- [ADV7513 datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ADV7513.pdf)
