#!/usr/bin/env python3
"""Generate gpio_layouts.svg, the three layouts of the Cmod A7 pins:

    1. every digital I/O pin of Cmod A7-35T, apart from the labs;
    2. the GPIO pins of the labs in the configurations with TM1638,
       the microphone and the DAC;
    3. the GPIO pins of the labs in the configurations without TM1638.

Run from any directory:

    python3 generate_gpio_diagram.py

Convert it to PNG, for example with Inkscape:

    inkscape gpio_layouts.svg --export-type=png --export-dpi=96 \\
        --export-background=white --export-filename=gpio_layouts.png

The pin data below must match board_specific.xdc and board_specific_top.sv.
"""

from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent

W = 1640
PANEL_H = 420
Y_PANELS = 118
H = Y_PANELS + 3 * PANEL_H + 40

FONT = "DejaVu Sans, Liberation Sans, Arial, sans-serif"
MONO = "DejaVu Sans Mono, Liberation Mono, monospace"

C = {
    "io": "#2f8f4e",
    "dac": "#8c5a3c",
    "tm": "#c99100",
    "mic": "#1a9a9a",
    "analog": "#7b4fa8",
    "vu": "#b0182a",
    "gnd": "#222222",
    "board": "#1d3f6e",
    "board_edge": "#0e2340",
    "chip": "#202020",
    "panel": "#f6f6f3",
    "panel_edge": "#d6d6cf",
    "text": "#1b1b1b",
    "muted": "#5b6170",
}

# The FPGA pins of the DIP pins and of Pmod JA, from board_specific.xdc

FPGA_PIN = {
    1: "M3", 2: "L3", 3: "A16", 4: "K3", 5: "C15", 6: "H1", 7: "A15",
    8: "B15", 9: "A14", 10: "J3", 11: "J1", 12: "K2", 13: "L1", 14: "L2",
    17: "M1", 18: "N3", 19: "P3", 20: "M2", 21: "N1", 22: "N2", 23: "P1",
    26: "R3", 27: "T3", 28: "R2", 29: "T1", 30: "T2", 31: "U1", 32: "W2",
    33: "V2", 34: "W3", 35: "V3", 36: "W5", 37: "V4", 38: "U4", 39: "V5",
    40: "W4", 41: "U5", 42: "U2", 43: "W6", 44: "U3", 45: "U7", 46: "W7",
    47: "U8", 48: "V8",
}

JA_PINS = [("JA1", "G17"), ("JA2", "G19"), ("JA3", "N18"), ("JA4", "L18"),
           ("JA7", "H17"), ("JA8", "H19"), ("JA9", "J19"), ("JA10", "K18")]

DIGITAL_PINS = (*range(1, 15), *range(17, 24), *range(26, 49))

# The GPIO pins of the labs, as in board_specific_top.sv: gpio [n] is on
# GPIO_PINS [n]. They run from DIP 48 down to 26, then from DIP 1 to 11,
# and without TM1638 on to its pins, DIP 12 to 14.

GPIO_PINS = (*range(48, 25, -1), *range(1, 12))
GPIO_PINS_NO_TM = (*GPIO_PINS, 12, 13, 14)

CONFIGS_TM = ("cmod_a7_35_tiny_vga_640_claude",
              "cmod_a7_35_no_pll_tiny_vga_304_claude",
              "cmod_a7_35_no_pll_tiny_vga_320_claude")
CONFIGS_NO_TM = tuple(name.replace("_claude", "_no_tm1638_claude") for name in CONFIGS_TM)

# Cmod A7 seen from the component side, Pmod JA on the left, USB on the
# right, as in the wiring diagrams: pins 48 to 25 run left to right along
# the top edge, pins 1 to 24 along the bottom edge.

X0, PITCH = 330, 34
BX0, BX1 = 290, 1150
BOARD_H = 130


def pin_x(pin):
    return X0 + (pin - 1) * PITCH if pin <= 24 else X0 + (48 - pin) * PITCH


class Svg:
    def __init__(self):
        self.parts = []

    def add(self, s):
        self.parts.append(s)

    def text(self, x, y, s, size=13, weight="normal", fill=None, anchor="start",
             family=FONT, rotate=None):
        fill = fill or C["text"]
        transform = f' transform="rotate({rotate} {x} {y})"' if rotate is not None else ""
        self.add(f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" '
                 f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}"{transform}>'
                 f'{escape(s)}</text>')

    def rect(self, x, y, w, h, fill, stroke="none", sw=1, rx=0):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
                 f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')

    def line(self, x1, y1, x2, y2, color, width=3):
        self.add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" '
                 f'stroke-width="{width}" stroke-linecap="round"/>')

    def pin(self, x, y, color):
        self.add(f'<circle cx="{x}" cy="{y}" r="7" fill="{color}" stroke="#ffffff" '
                 f'stroke-width="1.5"/>')

    def svg(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
                f'viewBox="0 0 {W} {H}">\n<rect width="{W}" height="{H}" fill="#ffffff"/>\n'
                + "\n".join(self.parts) + "\n</svg>\n")


def layouts():
    """The three layouts: title, subtitle, configurations, the label and the
    kind of each DIP pin, the groups to bracket, the Pmod JA text and the
    notes."""

    power = {15: ("analog", "analog"), 16: ("analog", "analog"),
             24: ("VU 5 V", "vu"), 25: ("GND", "gnd")}

    board = dict(power)
    board.update({pin: (FPGA_PIN[pin], "io") for pin in DIGITAL_PINS})

    modules = {17: ("SCK", "mic"), 18: ("WS", "mic"), 19: ("L/R", "mic"),
               20: ("SD", "mic"),
               21: ("BCK", "dac"), 22: ("DIN", "dac"), 23: ("LCK/WS", "dac")}

    with_tm = {**power, **modules}
    with_tm.update({pin: (f"gpio[{n}]", "io") for n, pin in enumerate(GPIO_PINS)})
    with_tm.update({12: ("STB", "tm"), 13: ("CLK", "tm"), 14: ("DIO", "tm")})

    without_tm = {**power, **modules}
    without_tm.update({pin: (f"gpio[{n}]", "io") for n, pin in enumerate(GPIO_PINS_NO_TM)})

    gpio_groups = [(26, 48, "gpio[0..22]", "io"), (1, 11, "gpio[23..33]", "io"),
                   (15, 16, "analog", "analog"), (17, 20, "INMP441", "mic"),
                   (21, 23, "DAC", "dac")]

    return [
        {
            "title": "1. Cmod A7-35T: every digital I/O pin",
            "subtitle": "The board alone, apart from the labs. "
                        "Each digital pin shows its FPGA pin.",
            "pins": board,
            "groups": [(1, 14, "digital I/O, 14 pins", "io"), (15, 16, "analog", "analog"),
                       (17, 23, "digital I/O, 7 pins", "io"),
                       (26, 48, "digital I/O, 23 pins", "io")],
            "ja": "io",
            "notes": [("52 digital I/O pins:", "bold"),
                      ("44 DIP pins: 1 to 14, 17 to 23, 26 to 48;", None),
                      ("8 Pmod JA pins: JA1 to JA4, JA7 to JA10.", None),
                      ("All are LVCMOS33: 3.3 V at most.", None),
                      ("DIP 15 and 16 are analog inputs of the", None),
                      ("XADC only. DIP 24 is VU, the 5 V of USB.", None),
                      ("On the board: 2 buttons, 2 LEDs, an RGB", None),
                      ("LED, the USB UART, the 12 MHz clock.", None)],
        },
        {
            "title": "2. The labs, with TM1638, the microphone and the DAC",
            "subtitle": "Configurations " + ", ".join(CONFIGS_TM),
            "pins": with_tm,
            "groups": [*gpio_groups, (12, 14, "TM1638", "tm")],
            "ja": "vga",
            "notes": [("34 GPIO pins of the labs:", "bold"),
                      ("gpio[0] to gpio[22] on DIP 48 down to 26,", None),
                      ("gpio[23] to gpio[33] on DIP 1 to 11.", None),
                      ("TM1638 on DIP 12 to 14, INMP441 on 17 to 20,", None),
                      ("DAC on 21 to 23, TinyVGA in Pmod JA.", None),
                      ("TM1638 gives the keys, the LEDs and the", None),
                      ("display; either button resets the design.", None)],
        },
        {
            "title": "3. The labs, without TM1638",
            "subtitle": "Configurations " + ", ".join(CONFIGS_NO_TM),
            "pins": without_tm,
            "groups": [*gpio_groups, (12, 14, "gpio[34..36]", "io")],
            "ja": "vga",
            "notes": [("37 GPIO pins of the labs:", "bold"),
                      ("the 34 of the configurations with TM1638,", None),
                      ("on the same DIP pins, and gpio[34] to", None),
                      ("gpio[36] on DIP 12 to 14, the pins of TM1638.", None),
                      ("The two buttons are the keys of the labs,", None),
                      ("the two LEDs are led[0] and led[1].", None)],
        },
    ]


def bracket(svg, first, last, text, kind, y, below):
    """A colored bar over the pins first to last, with its text outside."""
    xs = [pin_x(first), pin_x(last)]
    x0, x1 = min(xs) - 10, max(xs) + 10
    svg.line(x0, y, x1, y, C[kind], 4)
    ty = y + 19 if below else y - 9
    svg.text((x0 + x1) / 2, ty, text, 13, "bold", C[kind], "middle")


def draw_panel(svg, py, layout):
    svg.rect(20, py, W - 40, PANEL_H - 18, C["panel"], C["panel_edge"], 1.5, 10)
    svg.text(40, py + 34, layout["title"], 20, "bold")
    svg.text(40, py + 56, layout["subtitle"], 13, fill=C["muted"])

    by0 = py + 160
    by1 = by0 + BOARD_H
    y_top, y_bot = by0 + 20, by1 - 20

    # Cmod A7

    svg.rect(BX0, by0, BX1 - BX0, BOARD_H, C["board"], C["board_edge"], 2, 8)
    svg.rect(BX1 - 4, by0 + 35, 46, 60, "#c9ccd2", "#7d828c", 1.5, 4)
    svg.text(BX1 + 19, by0 + 70, "USB", 12, "bold", anchor="middle")
    svg.rect(370, by0 + 50, 110, 30, C["chip"], "#000000", 1, 4)
    svg.text(425, by0 + 70, "XC7A35T", 13, fill="#d8d8d8", anchor="middle")
    svg.text(680, by0 + 72, "Cmod A7-35T", 20, "bold", "#ffffff", "middle")
    svg.text(940, by0 + 71, "pins 48..25 on top, 1..24 below", 12, fill="#c7d3e6",
             anchor="middle")

    for pin in range(1, 49):
        x = pin_x(pin)
        label, kind = layout["pins"][pin]
        if pin <= 24:
            svg.pin(x, y_bot, C[kind])
            svg.text(x, y_bot - 13, str(pin), 11, fill="#ffffff", anchor="middle", family=MONO)
            svg.text(x + 4, by1 + 8, label, 12, "bold", C[kind], "end", MONO, rotate=-90)
        else:
            svg.pin(x, y_top, C[kind])
            svg.text(x, y_top + 23, str(pin), 11, fill="#ffffff", anchor="middle", family=MONO)
            svg.text(x + 4, by0 - 8, label, 12, "bold", C[kind], "start", MONO, rotate=-90)

    for first, last, text, kind in layout["groups"]:
        below = first <= 24
        bracket(svg, first, last, text, kind, by1 + 78 if below else by0 - 76, below)

    # Pmod JA

    svg.rect(BX0 - 34, by0 + 10, 40, BOARD_H - 20, "#2a2a2a", "#000000", 1, 3)
    svg.text(BX0 - 14, by0 + 70, "JA", 12, "bold", "#ffffff", "middle")
    if layout["ja"] == "io":
        svg.text(40, by0 - 4, "Pmod JA, 8 digital I/O", 13, "bold", C["io"])
        for i, (name, fpga) in enumerate(JA_PINS):
            x = 40 + 105 * (i // 4)
            y = by0 + 20 + 22 * (i % 4)
            svg.add(f'<circle cx="{x + 6}" cy="{y - 4}" r="5" fill="{C["io"]}"/>')
            svg.text(x + 16, y, f"{name} {fpga}", 12, "bold", C["io"], family=MONO)
        svg.text(40, by0 + 118, "JA5, JA11 GND", 12, fill=C["muted"], family=MONO)
        svg.text(40, by0 + 136, "JA6, JA12 3.3 V", 12, fill=C["muted"], family=MONO)
    else:
        svg.rect(60, by0 + 5, 180, 120, "#2b2b2b", "#000000", 1.5, 6)
        svg.text(150, by0 + 40, "TinyVGA", 18, "bold", "#ffffff", "middle")
        svg.text(150, by0 + 62, "in Pmod JA,", 13, fill="#d0d0d0", anchor="middle")
        svg.text(150, by0 + 80, "all 8 I/O pins", 13, fill="#d0d0d0", anchor="middle")
        svg.text(150, by0 + 106, "not GPIO", 12, "bold", "#ffe08a", "middle")

    # Notes

    for i, (s, weight) in enumerate(layout["notes"]):
        svg.text(1215, by0 - 40 + 24 * i, s, 14, weight or "normal",
                 C["text"] if weight else C["muted"])


def draw():
    svg = Svg()
    svg.text(40, 46, "Cmod A7-35T: the digital I/O pins and the GPIO pins of the labs",
             26, "bold")
    svg.text(40, 74, "Cmod A7 is seen from the component side, Pmod JA on the left and "
                     "USB on the right, as in the wiring diagrams. Each pin shows its "
                     "DIP pin number.", 15, fill=C["muted"])

    legend = [("digital I/O, GPIO", "io"), ("DAC", "dac"), ("TM1638", "tm"),
              ("INMP441", "mic"), ("analog input", "analog"), ("VU, 5 V", "vu"),
              ("GND", "gnd")]
    x = 40
    for label, kind in legend:
        svg.pin(x + 7, 97, C[kind])
        svg.text(x + 20, 102, label, 14)
        x += 50 + 8 * len(label)

    for i, layout in enumerate(layouts()):
        draw_panel(svg, Y_PANELS + i * PANEL_H, layout)

    svg.text(40, H - 16, "The GPIO pins take 3.3 V logic only, like every pin of Cmod A7. "
                         "gpio[n] of the labs is DIP pin 48 - n for n up to 22, and DIP pin "
                         "n - 22 from n = 23 on.", 14, fill=C["muted"])
    return svg.svg()


def main():
    out = HERE / "gpio_layouts.svg"
    out.write_text(draw(), encoding="utf-8")
    print(f"wrote {out.relative_to(HERE.parent)}")


if __name__ == "__main__":
    main()
