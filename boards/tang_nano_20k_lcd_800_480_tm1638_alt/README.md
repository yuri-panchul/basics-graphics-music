# Tang Nano 20K Documentation

The **Tang Nano 20K** is a compact FPGA development board designed by Sipeed. It is based on the GW2AR-18 FPGA chip and is suitable for a variety of applications, including digital signal processing, embedded systems, and hardware prototyping.

## Key Features
- **FPGA Chip**: GW2AR-18
- **Logic Cells**: 20,736
- **Block RAM**: 864 Kbits
- **32-bit SDR SDRAM**: 64 Mbits
- **Onboard Resources**:
  - **Debugger**: BL616 (JTAG, USB to UART, USB to SPI)
  - **Clock Generator**: MS5351 (provides multiple clocks)
  - **Display Interface**: 40-pin RGB LCD connector, HDMI interface
  - **LEDs**: 6 user-controllable LEDs
  - **RGB LED**: 1 WS2812 RGB LED for visual feedback
  - **User Buttons**: 2 buttons for input purposes
  - **TF Card Slot**: For external storage
  - **PCM Amplifier**: MAX98357A for audio driving
  - **Flash Storage**: 64 Mbits for saving bitstream
  - **Size**: 22.55mm x 54.04mm

## Pinout Diagram

![Tang Nano 20K Pinout](./tang_nano_20k_pinlabel.png)

See [IC -> Name mapping](./board_specific.cst) and [Name -> Use mapping](./board_specific_top.sv).

| Use             | Name    | IC  | Board | IC  | Name            | Use              |
|----------------:|--------:|----:|:-----:|----:|-----------------|------------------|
| INMP441: i2s_lr | GPIO[1] |  73 | USB-C |  5V |                 |                  |
| INMP441: i2s_ws | GPIO[2] |  74 | S1 S2 | GND |                 |                  |
| INMP441: i2s_sck| GPIO[3] |  75 | 6xLED |  76 |                 |                  |
| INMP441: i2s_sd | SD_DAT1 |  85 |       |  80 |                 |                  |
|                 |         |  77 | Si    |  42 |                 |                  |
|                 |         |  15 | PEED  |  41 |                 |                  |
|                 |         |  16 |       |  56 |                 |                  |
|                 |         |  27 |       |  54 |                 |                  |
|                 |         |  28 |       |  51 |                 |                  |
|                 |         |  25 | TANG  |  48 |                 |                  |
|                 |         |  26 |       |  55 |                 |                  |
|                 |         |  29 |       |  49 |                 |                  |
|                 |         |  30 | NANO  |  86 | GPIO[0]         | TM1638: sio_data |
|                 |         |  31 |       |  79 |                 |                  |
|                 |         |  17 |       | GND |                 | Ground           |
|                 |         |  20 | [20K] | 3V3 |                 | Power: 3.3V      |
|                 |         |  19 |       |  72 | JOYSTICK_CS2    | TM1638: sio_clk  |
|                 |         |  18 | HDMI  |  71 | JOYSTICK_MISO2  | TM1638: sio_stb  |
|                 |         | 3V3 |       |  53 |                 |                  |
|                 |         | GND |       |  52 |                 |                  |

For more detailed information and tutorials, please visit the [Tang Nano 20K Wiki](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html).
