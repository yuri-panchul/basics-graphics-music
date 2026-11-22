#!/usr/bin/env python3
"""Generate the wiring diagrams of the board configuration
cmod_a7_35_tiny_vga_640_claude.

Run from any directory:

    python3 generate_wiring_diagram.py

The other five Cmod A7 configurations share this wiring and use the
drawings of this directory; those without TM1638 leave out the module
and its wires.

It writes four diagrams, one for each pair of 3.3 V source and DAC module:

    wiring_weact_tph2.svg            wiring_weact_regulator.svg
    wiring_gy_pcm5102_tph2.svg       wiring_gy_pcm5102_regulator.svg

Convert them to PNG, for example with Inkscape:

    for f in wiring_*.svg
    do
        # ${f%.svg} is the file name without the .svg suffix
        inkscape "$f" --export-type=png --export-dpi=96 \\
            --export-background=white --export-filename="${f%.svg}.png"
    done

The pin data below must match board_specific_top.sv.
"""

from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent
BOARD = "cmod_a7_35_tiny_vga_640_claude"  # the name in the drawings

W, H = 1760, 1090

FONT = "DejaVu Sans, Liberation Sans, Arial, sans-serif"
MONO = "DejaVu Sans Mono, Liberation Mono, monospace"

C = {
    "TM": "#c99100",
    "DAC": "#8c5a3c",
    "MIC": "#1a9a9a",
    "3V3": "#ef7d1a",
    "5V": "#b0182a",
    "GND": "#222222",
    "board": "#1d3f6e",
    "board_edge": "#0e2340",
    "chip": "#202020",
    "module": "#f3f1ea",
    "module_edge": "#8a8577",
    "breadboard": "#f4f4f1",
    "breadboard_edge": "#c9c9c2",
    "text": "#1b1b1b",
    "muted": "#5b6170",
}

# DIP pins of Cmod A7 seen from the component side, Pmod JA on the left, USB
# on the right. Pins 48 to 25 run left to right along the top edge, pins 1
# to 24 along the bottom edge. The USB end of Cmod A7 is at the end of the
# breadboard, so that the USB cable leaves the breadboard; TinyVGA lies over
# the breadboard on the left.

BX0, BX1 = 700, 1560        # the edges of Cmod A7
BY0, BY1 = 300, 504
X0, PITCH = 740, 34
Y_TOP, Y_BOT = BY0 + 24, BY1 - 24

# The GPIO pins of the labs are the digital DIP pins that the modules do not
# use: gpio [0] to gpio [22] on DIP 48 down to 26, gpio [23] to gpio [33] on
# DIP 1 to 11. GPn is gpio [n]. Nothing is connected to them in these
# diagrams.

GPIO_PINS = (*range(48, 25, -1), *range(1, 12))
GPIO = {pin: f"GP{n}" for n, pin in enumerate(GPIO_PINS)}

USED = {
    **GPIO,
    12: "STB", 13: "CLK", 14: "DIO",
    15: "AIN", 16: "AIN",
    17: "SCK", 18: "WS", 19: "L/R", 20: "SD",
    21: "BCK", 22: "DIN", 23: "LCK/WS", 24: "VU",
    25: "GND",
}


def pin_xy(pin):
    if pin <= 24:
        return X0 + (pin - 1) * PITCH, Y_BOT
    return X0 + (48 - pin) * PITCH, Y_TOP


# Rails of the breadboard. The breadboard ends at the USB end of Cmod A7.

Y_3V3, Y_GND_TOP = 215, 245
Y_3V3_BOT, Y_GND_BOT = 660, 690
RAIL_X0, RAIL_X1 = 60, 1590

# The modules hang below the breadboard on jumper wires, with their header
# pins on their top edge. Their signal wires run in lanes between Cmod A7
# and the bottom rails: the wire of the leftmost DIP pin takes the top lane,
# so that no wires cross. Their power wires go up to the bottom rails.

Y_MODULE_PINS = 790
LANE_Y0, LANE_STEP = 518, 11
LANE_PINS = (12, 13, 14, 17, 18, 19, 20, 21, 22, 23)

TM_BOX = (200, 520)
TM_PINS = [("VCC", 240), ("GND", 290), ("STB", 360), ("CLK", 410), ("DIO", 460)]
MIC_BOX = (545, 915)
MIC_PINS = [("VDD", 595), ("GND", 645), ("SCK", 725), ("WS", 775), ("L/R", 825), ("SD", 875)]

DACS = {
    "weact": {
        "title": "WeAct I2S Earphone Module V1 (PCM5100A)",
        "short": "WeAct PCM5100A",
        "pins": [("VCC", 995), ("GND", 1045), ("/SD", 1105), ("MC", 1155),
                 ("BCK", 1235), ("DIN", 1285), ("WS", 1335)],
        "box": (945, 1385),
        "note": "/SD and MC stay unconnected: the module pulls /SD up and MC down.",
    },
    "gy_pcm5102": {
        "title": "GY-PCM5102 module (PCM5102A)",
        "short": "GY-PCM5102",
        "pins": [("SCK", 995), ("BCK", 1075), ("DIN", 1125), ("LCK", 1175),
                 ("GND", 1225), ("VIN", 1275)],
        "box": (945, 1385),
        "note": "SCK to GND. Solder jumpers on the back: FLT L, DEMP L, XSMT H, FMT L.",
    },
}

# The two 3.3 V sources

POWER = {
    "tph2": {
        "title": "3.3 V from Pmod TPH2",
        "rail_label": "+3.3 V rail, from TPH2",
        "note": "Unplug USB before changing the wiring. VU, DIP 24, stays unconnected: "
                "there is no 5 V on the breadboard, and the DIP pins take 3.3 V at most.",
    },
    "regulator": {
        "title": "3.3 V from a regulator",
        "rail_label": "+3.3 V rail, from the regulator",
        "note": "Unplug USB before changing the wiring. VU, DIP 24, goes to the regulator "
                "input only: the DIP pins take 3.3 V at most.",
    },
}

# The regulator hangs below the breadboard under DIP 24, VU, away from the
# DIP pins: its input wire, the only 5 V wire, goes straight up to DIP 24.

LDO = {"x0": 1405, "x1": 1615, "pins": [("OUT", 1450), ("GND", 1486), ("IN", 1522)]}


class Svg:
    def __init__(self, width):
        self.width = width
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

    def line(self, x1, y1, x2, y2, color, width=4):
        self.add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" '
                 f'stroke-width="{width}" stroke-linecap="round"/>')

    def wire(self, points, color, width=4):
        d = " ".join(f"{x},{y}" for x, y in points)
        self.add(f'<polyline points="{d}" fill="none" stroke="#ffffff" '
                 f'stroke-width="{width + 3}" stroke-linejoin="round" stroke-linecap="round"/>')
        self.add(f'<polyline points="{d}" fill="none" stroke="{color}" '
                 f'stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>')

    def dot(self, x, y, color, r=5):
        self.add(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}" stroke="#ffffff" stroke-width="1.5"/>')

    def pin(self, x, y, used=True):
        fill = "#f2c14e" if used else "#9aa3b2"
        self.add(f'<circle cx="{x}" cy="{y}" r="6" fill="{fill}" stroke="#5c4a12" stroke-width="1"/>')

    def svg(self):
        w = self.width
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{H}" '
                f'viewBox="0 0 {w} {H}">\n<rect width="{w}" height="{H}" fill="#ffffff"/>\n'
                + "\n".join(self.parts) + "\n</svg>\n")


def module(svg, box, title, subtitle, color, pins):
    """A module below the breadboard, its header pins on its top edge."""
    x0, x1 = box
    h = 150
    y0 = Y_MODULE_PINS
    svg.rect(x0, y0, x1 - x0, h, C["module"], C["module_edge"], 1.5, 6)
    svg.rect(x0, y0 + h - 10, x1 - x0, 10, color, rx=3)
    svg.text(x0 + 20, y0 + 70, title, 16, "bold")
    svg.text(x0 + 20, y0 + 90, subtitle, 12, fill=C["muted"])
    for label, x in pins:
        svg.pin(x, y0)
        svg.text(x, y0 + 26, label, 12, "bold", anchor="middle", family=MONO)


def signal_wire(svg, pin, x_module, color):
    """From a DIP pin down to its lane, along the lane, down to the module."""
    x, y = pin_xy(pin)
    lane = LANE_Y0 + LANE_STEP * LANE_PINS.index(pin)
    svg.wire([(x, y), (x, lane), (x_module, lane), (x_module, Y_MODULE_PINS)], color)


def power_wires(svg, pins, vcc, gnd):
    """The supply and GND pins of a module up to the bottom rails."""
    for name, y, color in ((vcc, Y_3V3_BOT, C["3V3"]), (gnd, Y_GND_BOT, C["GND"])):
        svg.wire([(pins[name], Y_MODULE_PINS), (pins[name], y)], color)
        svg.dot(pins[name], y, color)


def tinyvga(svg, x0, where):
    """TinyVGA, 190 wide, with its VGA socket on the left."""
    cx = x0 + 95
    y0 = BY0 + 27
    svg.rect(x0, y0, 190, 150, "#2b2b2b", "#000000", 1.5, 6)
    svg.rect(x0 - 28, y0 + 35, 34, 80, "#4a4f57", "#000000", 1, 4)
    svg.text(cx, y0 + 30, "TinyVGA", 18, "bold", "#ffffff", "middle")
    svg.text(cx, y0 + 50, where, 13, fill="#d0d0d0", anchor="middle")
    for i, s in enumerate(("1 R1  2 G1  3 B1  4 VS", "7 R0  8 G0  9 B0 10 HS",
                           "5, 11 GND   6, 12 3.3 V")):
        svg.text(cx, y0 + 80 + 20 * i, s, 11, fill="#ffffff", anchor="middle", family=MONO)
    svg.text(x0 - 16, y0 + 26, "VGA", 12, "bold", anchor="middle")


def draw(variant, power):
    dac, pw = DACS[variant], POWER[power]
    svg = Svg(W)

    # Title and legend

    svg.text(40, 46, f"Cmod A7-35T + TinyVGA + TM1638 + INMP441 + {dac['short']}, "
                     f"{pw['title']}", 26, "bold")
    svg.text(40, 76, f"Board configuration {BOARD}. The Cmod A7 sits in a breadboard across "
                     "its center channel, its USB end at the end of the breadboard; the modules "
                     "connect with jumper wires.", 15, fill=C["muted"])
    svg.text(40, 98, "Cmod A7 is seen from the component side. Each board pin shows its DIP "
                     "pin number; the used pins also show their signal.", 15, fill=C["muted"])

    legend = [("TM1638", C["TM"]), ("INMP441", C["MIC"]), ("DAC", C["DAC"]),
              ("+3.3 V", C["3V3"])]
    if power == "regulator":
        legend.append(("+5 V (VU)", C["5V"]))
    legend.append(("GND", C["GND"]))
    x = 40
    for label, color in legend:
        svg.line(x, 128, x + 30, 128, color, 5)
        svg.text(x + 38, 133, label, 14)
        x += 130

    # Breadboard and its rails

    svg.rect(RAIL_X0 - 10, Y_3V3 - 25, RAIL_X1 - RAIL_X0 + 20, Y_GND_BOT - Y_3V3 + 50,
             C["breadboard"], C["breadboard_edge"], 1.5, 10)
    svg.text(RAIL_X0 + 70, Y_3V3 - 8, pw["rail_label"], 13, "bold", C["3V3"])
    svg.text(RAIL_X0 + 70, Y_GND_TOP + 18, "GND rail", 13, "bold", C["GND"])

    # The labels of the bottom rails go in a gap between the wires

    svg.text(478, Y_3V3_BOT - 8, "+3.3 V rail", 13, "bold", C["3V3"])
    svg.text(478, Y_GND_BOT + 18, "GND rail", 13, "bold", C["GND"])
    for y, color in ((Y_3V3, C["3V3"]), (Y_GND_TOP, C["GND"]),
                     (Y_3V3_BOT, C["3V3"]), (Y_GND_BOT, C["GND"])):
        svg.line(RAIL_X0, y, RAIL_X1, y, color, 6)

    # The two + rails and the two GND rails joined at the far end of the
    # breadboard, away from USB

    svg.wire([(RAIL_X0 + 20, Y_3V3), (RAIL_X0 + 20, Y_3V3_BOT)], C["3V3"])
    svg.dot(RAIL_X0 + 20, Y_3V3, C["3V3"])
    svg.dot(RAIL_X0 + 20, Y_3V3_BOT, C["3V3"])
    svg.wire([(RAIL_X0 + 50, Y_GND_TOP), (RAIL_X0 + 50, Y_GND_BOT)], C["GND"])
    svg.dot(RAIL_X0 + 50, Y_GND_TOP, C["GND"])
    svg.dot(RAIL_X0 + 50, Y_GND_BOT, C["GND"])
    svg.text(RAIL_X0 + 66, BY0 + 90, "join the + rails", 12, "bold")
    svg.text(RAIL_X0 + 66, BY0 + 108, "and the GND rails", 12, "bold")

    # Cmod A7, its USB plug off the end of the breadboard

    svg.rect(BX0, BY0, BX1 - BX0, BY1 - BY0, C["board"], C["board_edge"], 2, 8)
    svg.line(BX1 + 42, BY0 + 102, W - 20, BY0 + 102, "#7d828c", 12)
    svg.rect(BX1 - 4, BY0 + 72, 46, 60, "#c9ccd2", "#7d828c", 1.5, 4)
    svg.text(BX1 + 19, BY0 + 107, "USB", 12, "bold", anchor="middle")
    svg.text(BX1 + 100, BY0 + 88, "USB cable", 13, "bold", C["muted"])

    # The chip and the name sit between the pin labels of the two rows

    svg.rect(BX0 + 80, BY0 + 89, 110, 32, C["chip"], "#000000", 1, 4)
    svg.text(BX0 + 135, BY0 + 110, "XC7A35T", 13, fill="#d8d8d8", anchor="middle")
    svg.text(BX0 + 350, BY0 + 111, "Cmod A7-35T", 24, "bold", "#ffffff", "middle")
    svg.text(BX0 + 610, BY0 + 110, "pins 48..25 on top, 1..24 below", 12, fill="#c7d3e6",
             anchor="middle")

    unconnected = (*GPIO, 15, 16, 24) if power == "tph2" else (*GPIO, 15, 16)
    for pin in range(1, 49):
        x, y = pin_xy(pin)
        used = pin in USED and pin not in unconnected
        svg.pin(x, y, used)
        if pin <= 24:
            svg.text(x, y - 13, str(pin), 11, fill="#ffffff", anchor="middle", family=MONO)
        else:
            svg.text(x, y + 22, str(pin), 11, fill="#ffffff", anchor="middle", family=MONO)
        if pin in USED:
            color = "#ffe08a" if used else "#9fb2cf"
            if pin <= 24:
                svg.text(x + 4, y - 26, USED[pin], 11, "bold", color, "start", MONO, rotate=-90)
            else:
                svg.text(x + 4, y + 34, USED[pin], 11, "bold", color, "end", MONO, rotate=-90)

    # Pmod JA, with TinyVGA in it, or TPH2 in it and TinyVGA in TPH2. Both
    # lie over the breadboard, the VGA socket facing up.

    svg.rect(BX0 - 34, BY0 + 32, 40, 140, "#2a2a2a", "#000000", 1, 3)
    svg.text(BX0 - 14, BY0 + 190, "JA", 12, "bold", anchor="middle")

    if power == "tph2":

        # TPH2 passes the Pmod pins through, and its test point 6 brings the
        # 3.3 V of the board to the + rail.

        tx0, tx1 = BX0 - 185, BX0 - 38
        tcx = (tx0 + tx1) / 2
        svg.rect(tx0, BY0 + 27, tx1 - tx0, 150, "#2e5a3c", "#14301e", 1.5, 6)
        svg.text(tcx, BY0 + 52, "TP 6: 3.3 V", 11, "bold", "#ffe08a", "middle", MONO)
        svg.text(tcx, BY0 + 84, "Pmod TPH2", 16, "bold", "#ffffff", "middle")
        for i, s in enumerate(("pass-through,", "test points 1..12", "= Pmod pins")):
            svg.text(tcx, BY0 + 106 + 18 * i, s, 11, fill="#d8e6dc", anchor="middle")
        svg.wire([(tcx, BY0 + 27), (tcx, Y_3V3)], C["3V3"])
        svg.pin(tcx, BY0 + 27)
        svg.dot(tcx, Y_3V3, C["3V3"])
        tinyvga(svg, tx0 - 195, "in TPH2")
    else:
        tinyvga(svg, BX0 - 230, "in Pmod JA")

    # DIP 25, GND, to the top GND rail

    x, y = pin_xy(25)
    svg.wire([(x + 9, y), (x + 9, Y_GND_TOP)], C["GND"])
    svg.dot(x + 9, Y_GND_TOP, C["GND"])

    # The regulator under DIP 24. VU, DIP 24, to its input is the only 5 V
    # wire.

    if power == "regulator":
        cx = (LDO["x0"] + LDO["x1"]) / 2
        svg.rect(LDO["x0"], Y_MODULE_PINS, LDO["x1"] - LDO["x0"], 100,
                 C["module"], C["module_edge"], 1.5, 6)
        svg.text(cx, Y_MODULE_PINS + 58, "3.3 V regulator", 15, "bold", anchor="middle")
        svg.text(cx, Y_MODULE_PINS + 78, "AMS1117-3.3 module", 12, fill=C["muted"],
                 anchor="middle")
        pins = dict(LDO["pins"])
        for label, x in LDO["pins"]:
            svg.pin(x, Y_MODULE_PINS)
            svg.text(x, Y_MODULE_PINS + 24, label, 11, "bold", anchor="middle", family=MONO)
        power_wires(svg, pins, "OUT", "GND")
        x, y = pin_xy(24)
        svg.wire([(x, y), (x, Y_MODULE_PINS)], C["5V"])

    # TM1638, INMP441 and the DAC below the breadboard, left of their DIP
    # pins

    module(svg, TM_BOX, "TM1638 LED&KEY", "8 digits, 8 LEDs, 8 keys; 3.3 V", C["TM"], TM_PINS)
    tm = dict(TM_PINS)
    power_wires(svg, tm, "VCC", "GND")
    for pin, label in ((12, "STB"), (13, "CLK"), (14, "DIO")):
        signal_wire(svg, pin, tm[label], C["TM"])

    module(svg, MIC_BOX, "INMP441 microphone", "I2S, 3.3 V", C["MIC"], MIC_PINS)
    mic = dict(MIC_PINS)
    power_wires(svg, mic, "VDD", "GND")
    for pin, label in ((17, "SCK"), (18, "WS"), (19, "L/R"), (20, "SD")):
        signal_wire(svg, pin, mic[label], C["MIC"])

    module(svg, dac["box"], dac["title"], "I2S DAC, 3.3 V", C["DAC"], dac["pins"])
    pins = dict(dac["pins"])
    power_wires(svg, pins, "VCC" if "VCC" in pins else "VIN", "GND")
    if "SCK" in pins:
        svg.wire([(pins["SCK"], Y_MODULE_PINS), (pins["SCK"], Y_GND_BOT)], C["GND"])
        svg.dot(pins["SCK"], Y_GND_BOT, C["GND"])
    for label in ("/SD", "MC"):
        if label in pins:
            svg.text(pins[label], Y_MODULE_PINS - 12, "n.c.", 11, fill=C["muted"], anchor="middle")
    lck = "WS" if "WS" in pins else "LCK"
    for pin, label in ((21, "BCK"), (22, "DIN"), (23, lck)):
        signal_wire(svg, pin, pins[label], C["DAC"])

    # Notes

    notes = [dac["note"],
             "INMP441 L/R is driven low by the FPGA; you may connect it to GND instead "
             "and leave DIP 19 free.",
             pw["note"],
             "DIP 48 to 26 and 1 to 11 are the GPIO pins of the labs, gpio[0] to gpio[33]; "
             "GPn is gpio[n]. Nothing is connected to them here."]
    for i, s in enumerate(notes):
        svg.text(40, 990 + 22 * i, s, 14, fill=C["muted"])

    return svg.svg()


def main():
    for variant in DACS:
        for power in POWER:
            out = HERE / f"wiring_{variant}_{power}.svg"
            out.write_text(draw(variant, power), encoding="utf-8")
            print(f"wrote {out.relative_to(HERE.parent)}")


if __name__ == "__main__":
    main()
