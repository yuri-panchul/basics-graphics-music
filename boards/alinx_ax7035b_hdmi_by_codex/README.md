# ALINX AX7035B HDMI output

The board wrapper sends the lab's RGB graphics to **HDMI1 (J6)** using
DVI-compatible video signaling. Connect that output to a monitor that accepts
640×480 video. HDMI2 is not used.

## Video mode

| Property | Value |
| --- | --- |
| Visible image | 640×480, 8 bits each for red, green, and blue |
| Pixel clock | 25 MHz |
| Total frame | 800×525 pixels, approximately 59.52 Hz |
| Horizontal timing | 640 visible, 16 front porch, 96 sync, 48 back porch |
| Vertical timing | 480 visible, 10 front porch, 2 sync, 33 back porch |
| Sync polarity | Negative horizontal and vertical sync |
| Lab clock | 50 MHz |
| Serializer clock | 125 MHz DDR, 250 Mbit/s per data lane |

This is a fixed video mode, using the repository's existing 25 MHz timing.
Changing the wrapper's screen or clock parameters alone does not select another
mode. The nominal 640×480 VGA pixel clock is 25.175 MHz; this implementation runs
slightly slower. There is no EDID negotiation, hot-plug detection, HDMI audio,
or HDCP support.

## Use

1. Connect the monitor to HDMI1 and connect the board's JTAG programmer.
2. Open a graphics lab, for example `labs/2_graphics/2_3_color_stripes`.
3. Run `./06_choose_another_fpga_board.bash` and select `alinx_ax7035b`.
4. Run `./03_synthesize_for_fpga.bash` to build and program the design using the
   existing Vivado flow. To program an existing build, run
   `./04_configure_fpga.bash`.

The wrapper honors `INSTANTIATE_GRAPHICS_INTERFACE_MODULE` from the lab
configuration, including the repository's default configuration. If that macro
is absent, the lab uses the original 50 MHz input clock and HDMI power is
disabled.

## Implementation

`ax7035b_hdmi.sv` derives phase-related lab, pixel, and serializer clocks from the
board's 50 MHz oscillator with an `MMCME2_BASE`. Reset asserts on the reset
button or loss of clock lock and releases through separate synchronizers in the
lab and pixel clock domains.

The common `dvi_sync` and `tmds_encoder` modules in `peripherals/dvi.sv` generate
video timing and TMDS symbols. Colors and sync signals are registered together.
Each output lane uses a master/slave pair of Artix-7 `OSERDESE2` primitives to
transmit ten bits, least significant bit first, followed by a `TMDS_33`
differential output buffer. The clock lane uses the same serializer arrangement
to maintain alignment with the data lanes.

The lab receives pixel coordinates and supplies RGB values using its existing
interface. Its clock remains 50 MHz; pixels advance at 25 MHz. Lab logic and
pixel logic use clocks from the same MMCM, so Vivado can time their crossings.

| HDMI1 signal | FPGA positive pin | FPGA negative pin |
| --- | --- | --- |
| Clock | E1 | D1 |
| Data 0: blue and sync | G1 | F1 |
| Data 1: green | H2 | G2 |
| Data 2: red | K1 | J1 |

Pin M6 (`HDMI_OEN[0]` in the wrapper) enables the connector's +5 V supply.
It is **active high**, despite the existing signal name. It goes high after
the pixel reset releases and low during reset or loss of lock.

Pin assignments and power-enable polarity follow the
[ALINX AX7035B user manual, HDMI section](https://alinx.com/public/upload/file/AX7035B_UG.pdf).
Serializer wiring follows AMD's
[OSERDESE2 primitive documentation](https://docs.amd.com/r/2024.2-English/ug953-vivado-7series-libraries/OSERDESE2).

## Simulation

`tests/hdmi_tb.sv` uses AMD's actual MMCM, serializer, and output-buffer models.
It decodes the transmitted differential signals, checks every active pixel and
blanking symbol in a complete frame, checks clock alignment, then repeats after
an asynchronous reset. Its test pattern encodes the coordinates into RGB to
detect swapped channels, incorrect bit order, and pixel alignment errors.

With Vivado's `settings64.sh` sourced, run these commands from the repository
root. Build products stay in a temporary directory.

```bash
repo="$PWD"
simulation_dir=$(mktemp -d)
cd "$simulation_dir"

xvlog --sv -i "$repo/labs/common" -i "$repo/peripherals" \
    "$repo/boards/alinx_ax7035b/ax7035b_hdmi.sv" \
    "$repo/peripherals/dvi.sv" \
    "$repo/boards/alinx_ax7035b/tests/hdmi_tb.sv" \
    "$XILINX_VIVADO/data/verilog/src/glbl.v"

xelab -L unisims_ver -L secureip work.hdmi_tb work.glbl \
    -s hdmi_test --debug typical

xsim hdmi_test -runall -onerror quit -onfinish quit
```

A successful run prints two `PASS: frame` messages and
`PASS: HDMI reset recovery`. Simulation does not replace checking the display
on a physical board.

## Validation

Validated with Vivado/XSim 2026.1 on `xc7a35tfgg484-2`:

- Both complete-frame simulation checks and reset recovery passed.
- The graphics-disabled wrapper passed a separate simulation checking its
  clock, reset, idle coordinates, and disabled HDMI outputs.
- The color-stripes lab completed synthesis, placement, routing, and bitstream
  generation with no DRC violations. Post-route setup slack was 35.483 ns and
  hold slack was 0.130 ns, with no unconstrained internal endpoints.

The timing results cover constrained FPGA paths. External HDMI output delays
are not specified in the XDC; board/cable timing and display compatibility have
not been tested on physical hardware.
