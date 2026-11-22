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

W, H = 1720, 1272

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

# DIP pins of Cmod A7 seen from the component side, Pmod JA on the left,
# USB on the right. Pins 48 to 25 run left to right along the top edge,
# pins 1 to 24 along the bottom edge.

X0, PITCH = 330, 34
Y_TOP, Y_BOT = 612, 768

# The GPIO pins of the labs are the digital DIP pins that the modules do not
# use, in the order of the DIP pins: gpio [0] to gpio [13] on DIP 1 to 14,
# gpio [14] to gpio [17] on DIP 17 to 20, gpio [18] to gpio [33] on DIP 33
# to 48. GPn is gpio [n]. Nothing is connected to them in these diagrams.

GPIO_PINS = (*range(1, 15), *range(17, 21), *range(33, 49))
GPIO = {pin: f"GP{n}" for n, pin in enumerate(GPIO_PINS)}

USED = {
    **GPIO,
    21: "BCK", 22: "DIN", 23: "LCK/WS", 24: "VU",
    25: "GND", 26: "STB", 27: "CLK", 28: "DIO",
    29: "SCK", 30: "WS", 31: "L/R", 32: "SD",
    15: "AIN", 16: "AIN",
}


def pin_xy(pin):
    if pin <= 24:
        return X0 + (pin - 1) * PITCH, Y_BOT
    return X0 + (48 - pin) * PITCH, Y_TOP


# Rails of the breadboard

Y_3V3, Y_GND_TOP = 505, 535
Y_3V3_BOT, Y_GND_BOT = 845, 875
RAIL_X0, RAIL_X1 = 250, 1690

# Modules: name -> list of (pin label, x); the pins are on the bottom edge
# of the modules above the board and on the top edge of those below it.

Y_TOP_MODULE_PINS = 395
Y_BOT_MODULE_PINS = 975

MIC_PINS = [("VDD", 530), ("GND", 580), ("SD", 660), ("L/R", 710), ("WS", 760), ("SCK", 810)]
TM_PINS = [("DIO", 1180), ("CLK", 1230), ("STB", 1280), ("GND", 1330), ("VCC", 1400)]

DACS = {
    "weact": {
        "title": "WeAct I2S Earphone Module V1 (PCM5100A)",
        "short": "WeAct PCM5100A",
        "pins": [("VCC", 820), ("GND", 870), ("/SD", 930), ("MC", 980),
                 ("BCK", 1060), ("DIN", 1110), ("WS", 1160)],
        "box": (770, 1210),
        "note": "/SD and MC stay unconnected: the module pulls /SD up and MC down.",
    },
    "gy_pcm5102": {
        "title": "GY-PCM5102 module (PCM5102A)",
        "short": "GY-PCM5102",
        "pins": [("SCK", 960), ("BCK", 1040), ("DIN", 1090), ("LCK", 1140),
                 ("GND", 1190), ("VIN", 1240)],
        "box": (910, 1350),
        "note": "SCK to GND. Solder jumpers on the back: FLT L, DEMP L, XSMT H, FMT L.",
    },
}

# The two 3.3 V sources. With TPH2 the board and the modules are drawn
# shifted right by "dx", which leaves room for TPH2 between JA and TinyVGA.

POWER = {
    "tph2": {
        "title": "3.3 V from Pmod TPH2",
        "dx": 150,
        "rail_label": "+3.3 V rail, from TPH2",
        "note": "Unplug USB before changing the wiring. VU, DIP 24, stays unconnected: "
                "there is no 5 V on the breadboard, and the DIP pins take 3.3 V at most.",
    },
    "regulator": {
        "title": "3.3 V from a regulator",
        "dx": 0,
        "rail_label": "+3.3 V rail, from the regulator",
        "note": "Unplug USB before changing the wiring. VU, DIP 24, goes to the regulator "
                "input only: the DIP pins take 3.3 V at most.",
    },
}

LDO = {"x0": 1255, "x1": 1445, "y0": 640, "y1": 740,
       "pins_top": [("GND", 1300), ("OUT 3.3 V", 1400)], "pin_bottom": ("IN", 1350)}
Y_VU_LANE = 815


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


def module(svg, x0, x1, y_pins, title, subtitle, color, pins, below):
    """A module drawn as a box with its header pins on one edge."""
    h = 150
    y0 = y_pins - h if not below else y_pins
    svg.rect(x0, y0, x1 - x0, h, C["module"], C["module_edge"], 1.5, 6)
    svg.rect(x0, y0, 10, h, color, rx=3)
    ty = y0 + 30 if not below else y0 + 70
    svg.text(x0 + 24, ty, title, 16, "bold")
    svg.text(x0 + 24, ty + 20, subtitle, 12, fill=C["muted"])
    for label, x in pins:
        svg.pin(x, y_pins)
        ly = y_pins - 16 if not below else y_pins + 26
        svg.text(x, ly, label, 12, "bold", anchor="middle", family=MONO)


def tinyvga(svg, x0, where):
    """TinyVGA, 190 wide, with its VGA socket on the left."""
    cx = x0 + 95
    svg.rect(x0, 615, 190, 150, "#2b2b2b", "#000000", 1.5, 6)
    svg.rect(x0 - 28, 650, 34, 80, "#4a4f57", "#000000", 1, 4)
    svg.text(cx, 645, "TinyVGA", 18, "bold", "#ffffff", "middle")
    svg.text(cx, 665, where, 13, fill="#d0d0d0", anchor="middle")
    for i, s in enumerate(("1 R1  2 G1  3 B1  4 VS", "7 R0  8 G0  9 B0 10 HS",
                           "5, 11 GND   6, 12 3.3 V")):
        svg.text(cx, 695 + 20 * i, s, 11, fill="#ffffff", anchor="middle", family=MONO)
    svg.text(x0 - 16, 643, "VGA", 12, "bold", anchor="middle")


def draw(variant, power):
    dac, pw = DACS[variant], POWER[power]
    dx = pw["dx"]
    svg = Svg(W + dx)

    # Title and legend

    svg.text(40, 46, f"Cmod A7-35T + TinyVGA + TM1638 + INMP441 + "
                     f"{dac['short']}, "
                     f"{pw['title']}", 26, "bold")
    svg.text(40, 76, f"Board configuration {BOARD}. The Cmod A7 sits in a breadboard across "
                     "its center channel; the modules connect with jumper wires.", 15, fill=C["muted"])
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

    svg.add(f'<g transform="translate({dx} 0)">')

    # Breadboard and its rails

    svg.rect(RAIL_X0 - 10, Y_3V3 - 25, RAIL_X1 - RAIL_X0 + 20, Y_GND_BOT - Y_3V3 + 50,
             C["breadboard"], C["breadboard_edge"], 1.5, 10)
    label_x = RAIL_X0 + 36 if power == "tph2" else RAIL_X0 + 4
    svg.text(label_x, Y_3V3 - 8, pw["rail_label"], 13, "bold", C["3V3"])
    svg.text(RAIL_X0 + 4, Y_GND_TOP + 18, "GND rail", 13, "bold", C["GND"])
    svg.text(RAIL_X0 + 4, Y_3V3_BOT - 8, "+3.3 V rail, joined to the one above", 13, "bold", C["3V3"])
    svg.text(RAIL_X0 + 4, Y_GND_BOT + 18, "GND rail", 13, "bold", C["GND"])
    for y, color in ((Y_3V3, C["3V3"]), (Y_GND_TOP, C["GND"]),
                     (Y_3V3_BOT, C["3V3"]), (Y_GND_BOT, C["GND"])):
        svg.line(RAIL_X0, y, RAIL_X1, y, color, 6)

    # Cmod A7

    bx0, bx1, by0, by1 = 290, 1150, 588, 792
    svg.rect(bx0, by0, bx1 - bx0, by1 - by0, C["board"], C["board_edge"], 2, 8)
    svg.rect(bx1 - 4, 660, 46, 60, "#c9ccd2", "#7d828c", 1.5, 4)
    svg.text(bx1 + 19, 695, "USB", 12, "bold", anchor="middle")
    # The chip and the name sit between the pin labels of the two rows

    svg.rect(370, 677, 110, 32, C["chip"], "#000000", 1, 4)
    svg.text(425, 698, "XC7A35T", 13, fill="#d8d8d8", anchor="middle")
    svg.text(640, 699, "Cmod A7-35T", 24, "bold", "#ffffff", "middle")
    svg.text(900, 698, "pins 48..25 on top, 1..24 below", 12, fill="#c7d3e6", anchor="middle")

    unconnected = (*GPIO, 15, 16, 24) if power == "tph2" else (*GPIO, 15, 16)
    labels = USED
    for pin in range(1, 49):
        x, y = pin_xy(pin)
        used = pin in labels and pin not in unconnected
        svg.pin(x, y, used)
        if pin <= 24:
            svg.text(x, y - 13, str(pin), 11, fill="#ffffff", anchor="middle", family=MONO)
        else:
            svg.text(x, y + 22, str(pin), 11, fill="#ffffff", anchor="middle", family=MONO)
        if pin in labels:
            name = labels[pin]
            color = "#ffe08a" if used else "#9fb2cf"
            if pin <= 24:
                svg.text(x + 4, y - 26, name, 11, "bold", color, "start", MONO, rotate=-90)
            else:
                svg.text(x + 4, y + 34, name, 11, "bold", color, "end", MONO, rotate=-90)

    # Pmod JA, with TinyVGA in it, or TPH2 in it and TinyVGA in TPH2

    svg.rect(bx0 - 34, 620, 40, 140, "#2a2a2a", "#000000", 1, 3)
    svg.text(bx0 - 14, 775, "JA", 12, "bold", anchor="middle")

    if power == "tph2":

        # TPH2 passes the Pmod pins through, and its test point 6 brings the
        # 3.3 V of the board to the + rail.

        tx0, tx1 = 105, 252
        tcx = (tx0 + tx1) / 2
        svg.rect(tx0, 615, tx1 - tx0, 150, "#2e5a3c", "#14301e", 1.5, 6)
        svg.text(tcx, 640, "TP 6: 3.3 V", 11, "bold", "#ffe08a", "middle", MONO)
        svg.text(tcx, 672, "Pmod TPH2", 16, "bold", "#ffffff", "middle")
        for i, s in enumerate(("pass-through,", "test points 1..12", "= Pmod pins")):
            svg.text(tcx, 694 + 18 * i, s, 11, fill="#d8e6dc", anchor="middle")
        svg.wire([(tcx, 615), (tcx, 470), (275, 470), (275, Y_3V3)], C["3V3"])
        svg.pin(tcx, 615)
        svg.dot(275, Y_3V3, C["3V3"])
        tinyvga(svg, tx0 - 195, "in TPH2")
    else:
        tinyvga(svg, 60, "in Pmod JA")

    # Power: GND to the GND rails, and the two + rails and the two GND
    # rails joined at the far end

    x, y = pin_xy(25)
    svg.wire([(x + 9, y), (x + 9, Y_GND_TOP)], C["GND"])
    svg.dot(x + 9, Y_GND_TOP, C["GND"])
    svg.wire([(1620, Y_3V3), (1620, Y_3V3_BOT)], C["3V3"])
    svg.dot(1620, Y_3V3, C["3V3"])
    svg.dot(1620, Y_3V3_BOT, C["3V3"])
    svg.wire([(1660, Y_GND_TOP), (1660, Y_GND_BOT)], C["GND"])
    svg.dot(1660, Y_GND_TOP, C["GND"])
    svg.dot(1660, Y_GND_BOT, C["GND"])
    svg.text(1610, 696, "join the + rails", 12, "bold", anchor="end")
    svg.text(1610, 714, "and the GND rails", 12, "bold", anchor="end")

    # The 3.3 V regulator. VU, DIP 24, to its input is the only 5 V wire.

    if power == "regulator":
        cx = (LDO["x0"] + LDO["x1"]) / 2
        svg.rect(LDO["x0"], LDO["y0"], LDO["x1"] - LDO["x0"], LDO["y1"] - LDO["y0"],
                 C["module"], C["module_edge"], 1.5, 6)
        svg.text(cx, 682, "3.3 V regulator", 15, "bold", anchor="middle")
        svg.text(cx, 700, "AMS1117-3.3 module", 12, fill=C["muted"], anchor="middle")
        for label, x in LDO["pins_top"]:
            svg.pin(x, LDO["y0"])
            svg.text(x, LDO["y0"] + 22, label, 11, "bold", anchor="middle", family=MONO)
        label, x_in = LDO["pin_bottom"]
        svg.pin(x_in, LDO["y1"])
        svg.text(x_in, LDO["y1"] - 10, label, 11, "bold", anchor="middle", family=MONO)
        x_gnd, x_out = LDO["pins_top"][0][1], LDO["pins_top"][1][1]
        svg.wire([(x_gnd, LDO["y0"]), (x_gnd, Y_GND_TOP)], C["GND"])
        svg.dot(x_gnd, Y_GND_TOP, C["GND"])
        svg.wire([(x_out, LDO["y0"]), (x_out, Y_3V3)], C["3V3"])
        svg.dot(x_out, Y_3V3, C["3V3"])
        x, y = pin_xy(24)
        svg.wire([(x, y), (x, Y_VU_LANE), (x_in, Y_VU_LANE), (x_in, LDO["y1"])], C["5V"])

    # INMP441, above the board on the left

    module(svg, 480, 850, Y_TOP_MODULE_PINS, "INMP441 microphone",
           "I2S, 3.3 V", C["MIC"], MIC_PINS, below=False)
    mic = dict(MIC_PINS)
    svg.wire([(mic["VDD"], Y_TOP_MODULE_PINS), (mic["VDD"], Y_3V3)], C["3V3"])
    svg.dot(mic["VDD"], Y_3V3, C["3V3"])
    svg.wire([(mic["GND"], Y_TOP_MODULE_PINS), (mic["GND"], Y_GND_TOP)], C["GND"])
    svg.dot(mic["GND"], Y_GND_TOP, C["GND"])

    # The module is to the left of its pins: the rightmost pin takes the
    # lane nearest to the module, so that no wires cross.

    lanes = {29: 425, 30: 445, 31: 465, 32: 485}
    for pin, label in ((29, "SCK"), (30, "WS"), (31, "L/R"), (32, "SD")):
        x, y = pin_xy(pin)
        svg.wire([(x, y), (x, lanes[pin]), (mic[label], lanes[pin]),
                  (mic[label], Y_TOP_MODULE_PINS)], C["MIC"])

    # TM1638, above the board on the right

    module(svg, 1130, 1450, Y_TOP_MODULE_PINS, "TM1638 LED&KEY",
           "8 digits, 8 LEDs, 8 keys; 3.3 V", C["TM"], TM_PINS, below=False)
    tm = dict(TM_PINS)
    svg.wire([(tm["VCC"], Y_TOP_MODULE_PINS), (tm["VCC"], Y_3V3)], C["3V3"])
    svg.dot(tm["VCC"], Y_3V3, C["3V3"])

    # The module is to the right of its pins: the leftmost pin takes the
    # lane nearest to the module.

    lanes = {28: 425, 27: 445, 26: 465, 25: 485}
    for pin, label, color in ((28, "DIO", C["TM"]), (27, "CLK", C["TM"]),
                              (26, "STB", C["TM"]), (25, "GND", C["GND"])):
        x, y = pin_xy(pin)
        svg.wire([(x, y), (x, lanes[pin]), (tm[label], lanes[pin]),
                  (tm[label], Y_TOP_MODULE_PINS)], color)

    # DAC, below the board

    x0, x1 = dac["box"]
    module(svg, x0, x1, Y_BOT_MODULE_PINS, dac["title"], "I2S DAC, 3.3 V", C["DAC"],
           dac["pins"], below=True)
    pins = dict(dac["pins"])
    power_pin = "VCC" if "VCC" in pins else "VIN"
    svg.wire([(pins[power_pin], Y_BOT_MODULE_PINS), (pins[power_pin], Y_3V3_BOT)], C["3V3"])
    svg.dot(pins[power_pin], Y_3V3_BOT, C["3V3"])
    svg.wire([(pins["GND"], Y_BOT_MODULE_PINS), (pins["GND"], Y_GND_BOT)], C["GND"])
    svg.dot(pins["GND"], Y_GND_BOT, C["GND"])
    if "SCK" in pins:
        svg.wire([(pins["SCK"], Y_BOT_MODULE_PINS), (pins["SCK"], Y_GND_BOT)], C["GND"])
        svg.dot(pins["SCK"], Y_GND_BOT, C["GND"])
    for label in ("/SD", "MC"):
        if label in pins:
            svg.text(pins[label], Y_BOT_MODULE_PINS - 12, "n.c.", 11, fill=C["muted"], anchor="middle")

    lanes = {21: 945, 22: 925, 23: 905}
    lck = "WS" if "WS" in pins else "LCK"
    for pin, label in ((21, "BCK"), (22, "DIN"), (23, lck)):
        x, y = pin_xy(pin)
        svg.wire([(x, y), (x, lanes[pin]), (pins[label], lanes[pin]),
                  (pins[label], Y_BOT_MODULE_PINS)], C["DAC"])

    svg.add("</g>")

    # Notes

    svg.text(40, 1170, dac["note"], 14, fill=C["muted"])
    svg.text(40, 1192, "INMP441 L/R is driven low by the FPGA; you may connect it to GND instead "
                       "and leave DIP 31 free.", 14, fill=C["muted"])
    svg.text(40, 1214, pw["note"], 14, fill=C["muted"])
    svg.text(40, 1236, "DIP 1 to 14, 17 to 20 and 33 to 48 are the GPIO pins of the labs, "
                       "gpio[0] to gpio[33]; GPn is gpio[n]. Nothing is connected to them here.",
             14, fill=C["muted"])

    return svg.svg()


def main():
    for variant in DACS:
        for power in POWER:
            out = HERE / f"wiring_{variant}_{power}.svg"
            out.write_text(draw(variant, power), encoding="utf-8")
            print(f"wrote {out.relative_to(HERE.parent)}")


if __name__ == "__main__":
    main()
