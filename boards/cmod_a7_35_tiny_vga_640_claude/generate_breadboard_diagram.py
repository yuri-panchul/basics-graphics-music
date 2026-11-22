#!/usr/bin/env python3
"""Generate the breadboard layouts of the board configuration
cmod_a7_35_tiny_vga_640_claude.

Unlike the wiring diagrams of generate_wiring_diagram.py, these drawings show
the holes of a full-size breadboard, with the INMP441 microphone, the DAC
module and the 3.3 V regulator of variant B plugged straight into it. Run from
any directory:

    python3 generate_breadboard_diagram.py

The boards cmod_a7_35_no_pll_tiny_vga_320_claude and
cmod_a7_35_no_pll_tiny_vga_304_claude share this wiring. Give the name of
one of them to write its drawings into its own directory, with its name in
the drawings:

    python3 generate_breadboard_diagram.py cmod_a7_35_no_pll_tiny_vga_320_claude

It writes breadboard_weact.svg and breadboard_gy_pcm5102.svg, one for each DAC
module. Convert them to PNG, for example with Inkscape:

    for f in breadboard_*.svg
    do
        # ${f%.svg} is the file name without the .svg suffix
        inkscape "$f" --export-type=png --export-dpi=96 \\
            --export-background=white --export-filename="${f%.svg}.png"
    done

The pin data below must match board_specific_top.sv.
"""

import sys
from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent
BOARD = "cmod_a7_35_tiny_vga_640_claude"  # the board directory to write to


def has_tm1638():
    """The configurations with _no_tm1638 in the name have no TM1638."""
    return "_no_tm1638" not in BOARD

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
    "text": "#1b1b1b",
    "muted": "#5b6170",
    "breadboard": "#f2f1ec",
    "breadboard_edge": "#c9c8bf",
    "hole": "#5e5e58",
    "red_line": "#d0453c",
    "blue_line": "#3a6fc4",
}

# The breadboard: 63 rows of holes, numbered along its length, and in each
# row two strips of five connected holes, a to e and f to j, on the two sides
# of the center channel. A pair of power rails runs along each long side.
#
# Positions across the breadboard are in units of the 0.1 inch pitch:

U = {"TO": 0, "TI": 1, "a": 3, "b": 4, "c": 5, "d": 6, "e": 7,
     "f": 10, "g": 11, "h": 12, "i": 13, "j": 14, "BI": 16, "BO": 17}
CHANNEL = 8.5
ROWS = 63

# The rails: top outer +3.3 V, top inner GND, bottom inner +3.3 V and bottom
# outer GND, as in the wiring diagrams. Their holes come in groups of five;
# here every sixth position is a gap.

RAILS = {"TO": "+3.3 V", "TI": "GND", "BI": "+3.3 V", "BO": "GND"}


def rail_hole(row):
    return row % 6 != 0


P = 24             # pixels per 0.1 inch
BX, BY = 360, 380  # position of row 1, rail TO
W = 1960


def X(row):
    return BX + (row - 1) * P


def Y(u):
    if isinstance(u, str):
        u = U[u]
    return BY + u * P


def xy(row, u):
    return X(row), Y(u)


# Cmod A7 sits across the channel with DIP pins 1 and 48 in row 1: pins 25 to
# 48 in column c, two holes from the channel, and pins 1 to 24 in column g,
# one hole from it. Row r holds DIP pins 49 - r and r. This leaves holes a
# and b free on one side and h, i and j on the other.

CMOD_TOP, CMOD_BOT = "c", "g"


def dip(pin):
    """The breadboard position of a DIP pin of Cmod A7."""
    if pin <= 24:
        return pin, CMOD_BOT
    return 49 - pin, CMOD_TOP


CMOD_NAMES = {21: "BCK", 22: "DIN", 23: "LCK", 24: "VU", 25: "GND", 26: "STB", 27: "CLK",
              28: "DIO", 29: "SCK", 30: "WS", 31: "L/R", 32: "SD"}
CMOD_FREE = (31,)  # DIP 31 stays free: INMP441 L/R goes to GND here

# The 3.3 V regulator of variant B: a 3-pin AMS1117-3.3 module, as Amazon
# B08CDMZMDN, listed as about 8.6 x 12.3 mm with the pins VIN, GND, VOUT. It
# goes in by its header in column j, with VIN in the strip of DIP 24, VU, so
# that no wire carries 5 V, and its body hangs over the bottom rails. The
# outline and the pin order come from the listing, not from a drawing.

REG_ROW = 24
REG_PINS = ["VIN", "GND", "VOUT"]
REG_MARGIN = 0.69  # from the outer pins to the board edges, in pitches
REG_DEPTH = 4.85   # the board from its header edge, in pitches

# INMP441 sits across the channel like a 6-pin DIP chip: its two rows of
# three pins are 0.3 inch apart, in columns e and f.

MIC_ROW = 44
MIC_TOP = ["SCK", "WS", "L/R"]   # column e, rows MIC_ROW to MIC_ROW + 2
MIC_BOT = ["SD", "VDD", "GND"]   # column f, SD opposite SCK

# The DAC modules go in by their header, in column j, with the module body
# and the headphone jack hanging over the rails and the edge of the
# breadboard. "body" is (rows before the first pin, rows after the last pin,
# depth beyond column j), in pitches.

DACS = {
    "weact": {
        "title": "WeAct I2S Earphone Module V1",
        "subtitle": "PCM5100A; 28.0 x 18.2 mm",
        "short": "WeAct PCM5100A",
        "row": 30,
        "pins": ["WS", "DIN", "BCK", "MC", "/SD", "GND", "VCC"],
        "ends": {"WS": "i", "DIN": "i", "BCK": "h"},
        "body": (0.6, 0.6, 10.4),
        "exact": True,
        "power": "VCC",
        "nc": ["MC", "/SD"],
        "notes": ["WeAct: /SD and MC stay unconnected; the module pulls /SD up and MC down.",
                  "Put the module in label side up, so that WS is the pin nearest to Cmod A7."],
    },
    "gy_pcm5102": {
        "title": "GY-PCM5102",
        "subtitle": "PCM5102A; outline approximate",
        "short": "GY-PCM5102",
        "row": 31,
        "pins": ["SCK", "BCK", "DIN", "LCK", "GND", "VIN"],
        "ends": {"BCK": "g", "DIN": "h", "LCK": "i"},
        "body": (1.0, 2.5, 8.6),
        "exact": False,
        "power": "VIN",
        "nc": [],
        "notes": ["GY-PCM5102: the pin order differs between board versions: connect by the labels. "
                  "SCK goes to GND. Solder jumpers: FLT L, DEMP L, XSMT H, FMT L.",
                  "Only the 6-pin header may go into the breadboard: keep any other pins of the board "
                  "off the holes."],
    },
}


class Svg:
    def __init__(self):
        self.parts = []

    def add(self, s):
        self.parts.append(s)

    def text(self, x, y, s, size=13, weight="normal", fill=None, anchor="start",
             family=FONT, rotate=None, opacity=None):
        fill = fill or C["text"]
        transform = f' transform="rotate({rotate} {x:.1f} {y:.1f})"' if rotate is not None else ""
        op = f' opacity="{opacity}"' if opacity is not None else ""
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{family}" font-size="{size}" '
                 f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}"{transform}{op}>'
                 f'{escape(s)}</text>')

    def rect(self, x, y, w, h, fill, stroke="none", sw=1, rx=0, opacity=None, dash=None):
        op = f' opacity="{opacity}"' if opacity is not None else ""
        da = f' stroke-dasharray="{dash}"' if dash else ""
        self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
                 f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{op}{da}/>')

    def circle(self, x, y, r, fill, stroke="none", sw=1, opacity=None):
        op = f' opacity="{opacity}"' if opacity is not None else ""
        self.add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{fill}" stroke="{stroke}" '
                 f'stroke-width="{sw}"{op}/>')

    def line(self, x1, y1, x2, y2, color, width=2, dash=None):
        da = f' stroke-dasharray="{dash}"' if dash else ""
        self.add(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{color}" '
                 f'stroke-width="{width}" stroke-linecap="round"{da}/>')

    def wire(self, d, color, width=4, dash=None):
        """A jumper wire along the SVG path d, with a white edge."""
        da = f' stroke-dasharray="{dash}"' if dash else ""
        self.add(f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="{width + 3}" '
                 f'stroke-linecap="round" stroke-linejoin="round"{da}/>')
        self.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
                 f'stroke-linecap="round" stroke-linejoin="round"{da}/>')

    def svg(self, h):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{h}" '
                f'viewBox="0 0 {W} {h}">\n<rect width="{W}" height="{h}" fill="#ffffff"/>\n'
                + "\n".join(self.parts) + "\n</svg>\n")


def path(points):
    """An SVG path through breadboard points (row, u): a straight line for two
    points, a cubic curve for four."""
    pts = [xy(r, u) for r, u in points]
    if len(pts) == 2:
        (x0, y0), (x1, y1) = pts
        return f"M{x0:.1f},{y0:.1f} L{x1:.1f},{y1:.1f}"
    s = f"M{pts[0][0]:.1f},{pts[0][1]:.1f}"
    for k in range(1, len(pts), 3):
        (a, b), (c, d), (e, f) = pts[k:k + 3]
        s += f" C{a:.1f},{b:.1f} {c:.1f},{d:.1f} {e:.1f},{f:.1f}"
    return s


def wire_end(svg, row, u, color):
    """The pin of a jumper wire in a hole."""
    x, y = xy(row, u)
    svg.circle(x, y, 5.5, color, "#ffffff", 1.5)


def strip(svg, row, top, color):
    """Tint the five connected holes of one strip."""
    u0 = U["a"] if top else U["f"]
    svg.rect(X(row) - 0.42 * P, Y(u0) - 0.42 * P, 0.84 * P, 4.84 * P, color, rx=5, opacity=0.22)


def draw(variant):
    dac = DACS[variant]
    svg = Svg()

    # Title and notes on top

    svg.text(40, 46, f"Breadboard layout: Cmod A7-35T, INMP441, {dac['short']} "
                     f"and the 3.3 V regulator", 26, "bold")
    svg.text(40, 76, f"Board configuration {BOARD}, seen from above. The microphone, the DAC "
                     "and the 3.3 V regulator of variant B go straight into the breadboard; "
                     + ("TinyVGA and TM1638 connect" if has_tm1638() else "TinyVGA connects")
                     + " as in the wiring diagrams.", 15, fill=C["muted"])
    svg.text(40, 98, "Tinted holes are the strips in use: the five holes of a strip are "
                     "connected. A dot is a jumper wire in a hole.", 15, fill=C["muted"])
    tm = has_tm1638()
    legend = [("TM1638", C["TM"])] if tm else []
    legend += [("INMP441", C["MIC"]), ("DAC", C["DAC"]), ("+3.3 V", C["3V3"]), ("GND", C["GND"])]
    x = 40
    for label, color in legend:
        svg.line(x, 128, x + 30, 128, color, 5)
        svg.text(x + 38, 133, label, 14)
        x += 115
    svg.rect(x, 121, 30, 14, C["5V"], rx=3, opacity=0.3)
    svg.text(x + 38, 133, "VU strip, about 5 V", 14)

    # Breadboard

    bx0, bx1 = X(1) - 1.2 * P, X(ROWS) + 1.4 * P
    svg.rect(bx0, Y("TO") - 1.2 * P, bx1 - bx0, (U["BO"] + 2.4) * P, C["breadboard"],
             C["breadboard_edge"], 1.5, 10)
    svg.rect(bx0 + 6, Y(CHANNEL) - 0.7 * P, bx1 - bx0 - 12, 1.4 * P, "#e2e0d8", rx=3)
    for rail, color in (("TO", C["red_line"]), ("TI", C["blue_line"]),
                        ("BI", C["red_line"]), ("BO", C["blue_line"])):
        side = -0.55 if rail in ("TO", "BI") else 0.55
        svg.line(X(1) - 0.6 * P, Y(rail) + side * P, X(ROWS) + 0.6 * P, Y(rail) + side * P,
                 color, 1.5)
        for row in range(1, ROWS + 1):
            if rail_hole(row):
                svg.rect(X(row) - 3.5, Y(rail) - 3.5, 7, 7, C["hole"], rx=1.5)
    for row in range(1, ROWS + 1):
        for col in "abcdefghij":
            svg.rect(X(row) - 3.5, Y(col) - 3.5, 7, 7, C["hole"], rx=1.5)
    for row in [1] + list(range(5, ROWS + 1, 5)):
        for u in (2, 15.1):
            svg.text(X(row), Y(u) + 4, str(row), 10, fill=C["muted"], anchor="middle", family=MONO)
    for col in "abcdefghij":
        svg.text(X(ROWS) + 1.0 * P, Y(col) + 4, col, 11, fill=C["muted"], anchor="middle",
                 family=MONO)
    for rail, name in RAILS.items():
        color = C["3V3"] if name.startswith("+") else C["GND"]
        svg.text(X(ROWS) + 0.95 * P, Y(rail) + 4, "+" if name.startswith("+") else "−", 13,
                 "bold", color, "middle")

    # Tint the strips in use

    tints = [(17, True, C["MIC"]), (19, True, C["MIC"]), (20, True, C["MIC"])]
    if tm:
        tints += [(21, True, C["TM"]), (22, True, C["TM"]), (23, True, C["TM"])]
    tints += [(24, True, C["GND"]),
              (21, False, C["DAC"]), (22, False, C["DAC"]), (23, False, C["DAC"])]
    for k, name in enumerate(REG_PINS):
        tints.append((REG_ROW + k, False, {"VIN": C["5V"], "GND": C["GND"],
                                           "VOUT": C["3V3"]}[name]))
    for k in range(3):
        tints.append((MIC_ROW + k, True, C["GND"] if MIC_TOP[k] == "L/R" else C["MIC"]))
        bot = MIC_BOT[k]
        tints.append((MIC_ROW + k, False, C["3V3"] if bot == "VDD" else
                      C["GND"] if bot == "GND" else C["MIC"]))
    for k, name in enumerate(dac["pins"]):
        if name in dac["nc"]:
            continue
        color = (C["3V3"] if name == dac["power"] else
                 C["GND"] if name in ("GND", "SCK") else C["DAC"])
        tints.append((dac["row"] + k, False, color))
    for row, top, color in tints:
        strip(svg, row, top, color)

    # Cmod A7

    cx0, cx1 = X(1) - 3.5 * P, X(24) + 0.9 * P
    cy0, cy1 = Y(CMOD_TOP) - 0.5 * P, Y(CMOD_BOT) + 0.5 * P
    svg.rect(cx0, cy0, cx1 - cx0, cy1 - cy0, C["board"], C["board_edge"], 2, 6)
    cmid = (U[CMOD_TOP] + U[CMOD_BOT]) / 2
    svg.rect(cx1 - 6, Y(cmid) - 0.95 * P, 1.1 * P, 1.9 * P, "#c9ccd2", "#7d828c", 1.5, 3)
    svg.text(cx1 + 0.45 * P - 6, Y(cmid) + 4, "USB", 10, "bold", anchor="middle")
    svg.rect(X(3), Y(cmid - 1.2), 3.6 * P, 1.7 * P, "#202020", "#000000", 1, 3)
    svg.text(X(3) + 1.8 * P, Y(cmid - 0.35) + 4, "XC7A35T", 11, fill="#d8d8d8", anchor="middle")
    svg.text(X(13), Y(cmid) + 2, "Cmod A7-35T", 22, "bold", "#ffffff", "middle")
    svg.text(X(13), Y(cmid) + 20, "pins 48..25 in column c, 1..24 in column g", 10,
             fill="#c7d3e6", anchor="middle")
    for pin in range(1, 49):
        row, col = dip(pin)
        x, y = xy(row, col)
        svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
        ny = y + 17 if col == CMOD_TOP else y - 10
        svg.text(x, ny, str(pin), 9, fill="#ffffff", anchor="middle", family=MONO)
        if pin in CMOD_NAMES and (tm or pin not in (26, 27, 28)):
            color = "#9fb2cf" if pin in CMOD_FREE else "#ffe08a"
            if col == CMOD_TOP:
                svg.text(x + 3.5, y + 24, CMOD_NAMES[pin], 9, "bold", color, "end", MONO, rotate=-90)
            else:
                svg.text(x + 3.5, y - 20, CMOD_NAMES[pin], 9, "bold", color, "start", MONO, rotate=-90)

    # The GPIO pins of the labs, in the order of the DIP pins; nothing is
    # connected to them. Pins 48 to 33 run left to right, so the labels of
    # the top row count down.

    for first, last, label in ((1, 14, "GPIO 0 to 13"), (17, 20, "GPIO 14 to 17"),
                               (48, 33, "GPIO 33 to 18")):
        (x0, y0), (x1, _) = xy(*dip(first)), xy(*dip(last))
        gy = y0 + 31 if dip(first)[1] == CMOD_TOP else y0 - 22
        svg.text((x0 + x1) / 2, gy, label, 9, "bold", "#9fb2cf", "middle", MONO)

    # Pmod JA and TinyVGA, off the end of the breadboard

    svg.rect(cx0 - 0.9 * P, Y(cmid - 2.5), 1.0 * P, 5 * P, "#2a2a2a", "#000000", 1, 3)
    svg.text(cx0 - 0.4 * P, Y(cmid + 2.5) + 16, "JA", 11, "bold", anchor="middle")
    tv1 = cx0 - 0.9 * P
    tv0 = tv1 - 190
    svg.rect(tv0, Y(cmid) - 75, 190, 150, "#2b2b2b", "#000000", 1.5, 6)
    svg.rect(tv0 - 28, Y(cmid) - 40, 34, 80, "#4a4f57", "#000000", 1, 4)
    svg.text(tv0 + 95, Y(cmid) - 42, "TinyVGA", 17, "bold", "#ffffff", "middle")
    for k, s in enumerate(("in Pmod JA;", "in variant A", "through Pmod TPH2")):
        svg.text(tv0 + 95, Y(cmid) - 18 + 18 * k, s, 12, fill="#d0d0d0", anchor="middle")

    if tm:
        # TM1638, off the breadboard above it, and its wires

        tm_y = Y("TO") - 6.6 * P
        tm_pins = [("DIO", 21), ("CLK", 22), ("STB", 23), ("GND", 24), ("VCC", 25)]
        svg.rect(X(19), tm_y - 3.6 * P, X(34) - X(19), 3.6 * P, "#f3f1ea", "#8a8577", 1.5, 6)
        svg.rect(X(19), tm_y - 3.6 * P, 10, 3.6 * P, C["TM"], rx=3)
        svg.text(X(19) + 22, tm_y - 2.55 * P, "TM1638 LED&KEY, off the breadboard", 14, "bold")
        svg.text(X(19) + 22, tm_y - 1.75 * P, "female-to-male wires to its 5-pin header", 11,
                 fill=C["muted"])
        for name, row in tm_pins:
            svg.circle(X(row), tm_y, 5, "#f2c14e", "#5c4a12", 1)
            svg.text(X(row), tm_y - 10, name, 9, "bold", anchor="middle", family=MONO)
        for name, row in tm_pins[:4]:
            color = C["GND"] if name == "GND" else C["TM"]
            svg.wire(f"M{X(row):.1f},{Y('a'):.1f} L{X(row):.1f},{tm_y:.1f}", color)
            wire_end(svg, row, "a", color)
        svg.wire(f"M{X(25):.1f},{Y('TO'):.1f} L{X(25):.1f},{tm_y:.1f}", C["3V3"])
        wire_end(svg, 25, "TO", C["3V3"])
    else:
        ny0 = Y("TO") - 9.6 * P
        svg.text(X(19), ny0, "No TM1638 in this configuration:", 14, "bold")
        svg.text(X(19), ny0 + 18, "the labs use the two buttons and the two LEDs of "
                 "Cmod A7; DIP 26, 27 and 28 stay unconnected.", 12, fill=C["muted"])

    # DIP 25, GND, to the top GND rail

    svg.wire(path([(24, "c"), (26, "TI")]), C["GND"])
    wire_end(svg, 24, "c", C["GND"])
    wire_end(svg, 26, "TI", C["GND"])

    # The DAC module, plugged in by its header in column j

    row0 = dac["row"]
    n = len(dac["pins"])
    before, after, depth = dac["body"]
    dx0, dx1 = X(row0) - before * P - 0.5 * P, X(row0 + n - 1) + after * P + 0.5 * P
    dy0, dy1 = Y("j") - 0.6 * P, Y("j") + depth * P
    svg.rect(dx0, dy0, dx1 - dx0, dy1 - dy0, "#ece6dc", "#8a8577", 1.5, 5, opacity=0.95,
             dash=None if dac["exact"] else "7 4")
    svg.rect(dx0, dy1 - 10, dx1 - dx0, 10, C["DAC"], rx=3)
    jx = dx0 + (dx1 - dx0) * (0.19 if dac["exact"] else 0.3)
    svg.rect(jx - 0.9 * P, dy1 - 2.2 * P, 1.8 * P, 2.6 * P, "#3a3a3a", "#000000", 1, 3)
    svg.text(jx, dy1 + 18, "3.5 mm jack", 11, "bold", anchor="middle")
    svg.text(jx + 1.3 * P, dy1 - 1.4 * P, dac["title"], 13, "bold")
    svg.text(jx + 1.3 * P, dy1 - 1.4 * P + 16, dac["subtitle"] + "; I2S DAC, 3.3 V", 11,
             fill=C["muted"])
    for k, name in enumerate(dac["pins"]):
        x, y = xy(row0 + k, "j")
        svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
        svg.text(x + 3.5, y + 14, name, 10, "bold", anchor="end", family=MONO, rotate=-90)
        if name in dac["nc"]:
            svg.text(x, Y("j") + 2.25 * P, "n.c.", 9, fill=C["muted"], anchor="middle")

    # Cmod A7 to the DAC. The wires run in three lanes, BCK highest, between
    # the edge of Cmod A7 and the wires of the regulator; each ends in the
    # hole of its DAC strip that keeps them from crossing.

    pin_row = {name: row0 + k for k, name in enumerate(dac["pins"])}
    lck = "WS" if "WS" in pin_row else "LCK"
    for dip_pin, name, start, lane in ((21, "BCK", "h", 11.7), (22, "DIN", "i", 12.1),
                                       (23, lck, "i", 12.5)):
        r1, u1 = pin_row[name], U[dac["ends"][name]]
        a, b = dip_pin + 1.3, r1 - 1.4  # the straight part along the lane
        d = path([(dip_pin, start), (dip_pin + 0.3, lane), (dip_pin + 0.8, lane), (a, lane),
                  (a + (b - a) / 3, lane), (b - (b - a) / 3, lane), (b, lane),
                  (r1 - 0.6, lane), (r1, lane + 0.3 * (u1 - lane)), (r1, u1)])
        svg.wire(d, C["DAC"])
        wire_end(svg, dip_pin, start, C["DAC"])
        wire_end(svg, r1, u1, C["DAC"])

    # DAC power, and SCK of GY-PCM5102, to the top rails: the module covers
    # the bottom rails next to it.

    r_gnd, r_pwr = pin_row["GND"], pin_row[dac["power"]]
    svg.wire(path([(r_gnd, "f"), (r_gnd, "TI")]), C["GND"])
    wire_end(svg, r_gnd, "f", C["GND"])
    wire_end(svg, r_gnd, "TI", C["GND"])
    d = path([(r_pwr, "f"), (r_pwr + 0.15, 4.0), (r_pwr + 1.1, 1.6), (r_pwr + 2, "TO")])
    svg.wire(d, C["3V3"])
    wire_end(svg, r_pwr, "f", C["3V3"])
    wire_end(svg, r_pwr + 2, "TO", C["3V3"])
    if "SCK" in pin_row:
        r_sck = pin_row["SCK"]
        svg.wire(path([(r_sck, "f"), (r_sck + 1, "TI")]), C["GND"])
        wire_end(svg, r_sck, "f", C["GND"])
        wire_end(svg, r_sck + 1, "TI", C["GND"])

    # The regulator, plugged in by its header in column j, VIN in the strip
    # of DIP 24. Its body hangs over the bottom rails, so GND goes to the GND
    # rail before it and VOUT to the + rail after it, both under the DAC wires.

    reg_row = {name: REG_ROW + k for k, name in enumerate(REG_PINS)}
    r_first, r_last = REG_ROW, REG_ROW + len(REG_PINS) - 1
    rx0, rx1 = X(r_first - REG_MARGIN), X(r_last + REG_MARGIN)
    ry0 = Y("j") - 0.5 * P
    ry1 = ry0 + REG_DEPTH * P
    svg.rect(rx0, ry0, rx1 - rx0, ry1 - ry0, "#dde7f3", "#4f6f99", 1.5, 4, opacity=0.95,
             dash="7 4")
    chip_w, chip_h = 2.3 * P, 1.45 * P
    chip_x, chip_y = (rx0 + rx1) / 2 - chip_w / 2, ry1 - chip_h - 0.35 * P
    svg.rect(chip_x + 0.3 * P, chip_y - 0.45 * P, chip_w - 0.6 * P, 0.5 * P, "#8d939c", rx=1)
    svg.rect(chip_x, chip_y, chip_w, chip_h, "#262626", "#000000", 1, 2)
    svg.text((rx0 + rx1) / 2, chip_y + chip_h / 2 + 3, "AMS1117", 8, "bold", "#d8d8d8",
             "middle")
    for name, row in reg_row.items():
        x, y = xy(row, "j")
        svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
        svg.text(x + 3.5, y + 14, name, 10, "bold", anchor="end", family=MONO, rotate=-90)

    r = reg_row["GND"]
    svg.wire(path([(r, "i"), (r - 0.6, 13.15), (r - 1.1, 13.15), (r - 1.6, 13.15),
                   (r - 2.4, 13.15), (r - 3.0, 14.0), (r - 3.0, "BO")]), C["GND"])
    wire_end(svg, r, "i", C["GND"])
    wire_end(svg, r - 3, "BO", C["GND"])
    r = reg_row["VOUT"]
    svg.wire(path([(r, "i"), (r + 1.5, 13.05), (r + 2.0, 13.8), (r + 2.0, "BI")]), C["3V3"])
    wire_end(svg, r, "i", C["3V3"])
    wire_end(svg, r + 2, "BI", C["3V3"])

    svg.text(rx1, ry1 + 18, "3.3 V regulator, AMS1117-3.3 module", 12, "bold", anchor="end")
    svg.text(rx1, ry1 + 34, "VIN in the strip of DIP 24, VU; outline approximate", 11,
             fill=C["muted"], anchor="end")

    # INMP441, across the channel

    mx, my = X(MIC_ROW + 1), Y(CHANNEL)
    svg.circle(mx, my, 2.75 * P, "#1c1c1c", "#c58b3a", 3, opacity=0.93)
    for k in range(3):
        for col, names, ly in (("e", MIC_TOP, 0.85), ("f", MIC_BOT, -0.6)):
            x, y = xy(MIC_ROW + k, col)
            svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
            svg.text(x, y + ly * P, names[k], 9, "bold", "#ffffff", "middle", MONO)
    svg.text(mx, my + 4, "INMP441", 10, "bold", "#d8d8d8", "middle")
    svg.text(mx + 3.1 * P, my - 0.2 * P, "INMP441,", 12, "bold")
    svg.text(mx + 3.1 * P, my + 0.5 * P, "label side up", 11, fill=C["muted"])

    # INMP441 power and L/R

    r_sck, r_ws, r_lr = MIC_ROW, MIC_ROW + 1, MIC_ROW + 2
    svg.wire(path([(r_lr, "b"), (r_lr + 1, "TI")]), C["GND"])
    wire_end(svg, r_lr, "b", C["GND"])
    wire_end(svg, r_lr + 1, "TI", C["GND"])
    svg.wire(path([(r_ws, "j"), (r_ws, "BI")]), C["3V3"])
    wire_end(svg, r_ws, "j", C["3V3"])
    wire_end(svg, r_ws, "BI", C["3V3"])
    svg.wire(path([(r_lr, "j"), (r_lr + 3, "BO")]), C["GND"])
    wire_end(svg, r_lr, "j", C["GND"])
    wire_end(svg, r_lr + 3, "BO", C["GND"])

    # Cmod A7 to INMP441: curves over the TM1638 wires; SD comes down to
    # the other side of the channel just before the microphone.

    for dip_pin, row1, height in ((29, r_sck, -2.0), (30, r_ws, -3.0)):
        r0 = dip(dip_pin)[0]
        d = path([(r0, "a"), (r0 - 0.3, height - 1.5), (row1 + 0.9, height - 1.0), (row1, "a")])
        svg.wire(d, C["MIC"])
        wire_end(svg, r0, "a", C["MIC"])
        wire_end(svg, row1, "a", C["MIC"])
    r0 = dip(32)[0]
    sd_x = MIC_ROW - 2.5
    d = path([(r0, "a"), (r0 - 0.3, -6.0), (sd_x, -6.0), (sd_x, 2.0),
              (sd_x, 6.0), (sd_x, 9.5), (sd_x + 0.6, 11.2),
              (sd_x + 1.2, 12.6), (MIC_ROW - 0.6, 12.4), (MIC_ROW, "h")])
    svg.wire(d, C["MIC"])
    wire_end(svg, r0, "a", C["MIC"])
    wire_end(svg, MIC_ROW, "h", C["MIC"])

    # Join the + rails and the GND rails at the far end of the breadboard

    jr = ROWS - 1
    d = path([(jr, "TO"), (jr + 3.2, 3.0), (jr + 3.2, 13.0), (jr, "BI")])
    svg.wire(d, C["3V3"])
    wire_end(svg, jr, "TO", C["3V3"])
    wire_end(svg, jr, "BI", C["3V3"])
    d = path([(jr - 1, "TI"), (jr + 4.6, 2.0), (jr + 4.6, 15.0), (jr - 1, "BO")])
    svg.wire(d, C["GND"])
    wire_end(svg, jr - 1, "TI", C["GND"])
    wire_end(svg, jr - 1, "BO", C["GND"])

    # Labels of the rails

    svg.text(X(1) - 1.0 * P, Y("TO") - 0.75 * P, "+3.3 V from the regulator (variant A: from TPH2)",
             11, "bold", C["3V3"])
    svg.text(X(1) - 1.0 * P, Y("BO") + 1.0 * P + 4, "Both + rails and both GND rails are joined "
             "at the far end.", 11, "bold", C["GND"])

    # Notes

    notes = ["INMP441 goes across the center channel like a 6-pin DIP chip, SCK, WS, L/R on the "
             "side of DIP 25 to 48. L/R goes to GND here, so DIP 31 stays free.",
             "The DAC goes in by its header in column j; its body and jack hang over the bottom "
             "rails and the edge of the breadboard, so it takes its power from the top rails.",
             "The regulator of variant B is a 3-pin AMS1117-3.3 module, as Amazon B08CDMZMDN. It "
             "goes in by its header in column j, rows 24 to 26, so VIN is in the strip of DIP 24, "
             "VU, and no wire carries 5 V.",
             "Its pin order, VIN, GND, VOUT from the Cmod A7 end, and its outline come from the "
             "listing: check the labels. If VIN is at the other end, connect the module by wires "
             "as in the variant B wiring diagram.",
             "Variant A, Pmod TPH2: leave the regulator out and wire test point 6 of TPH2 to the "
             "+ rail; DIP 24, VU, then stays unconnected.",
             "Keep the middle of rows 25 to 29 free for the USB plug. "
             "Unplug USB before changing the wiring.",
             "DIP 1 to 14, 17 to 20 and 33 to 48 are the GPIO pins of the labs, gpio[0] to "
             "gpio[33]; nothing is connected to them here."] + dac["notes"]
    ny = 1018
    for k, s in enumerate(notes):
        svg.text(40, ny + 20 * k, s, 13, fill=C["muted"])

    return svg.svg(ny + 20 * len(notes) + 8)


def main():
    global BOARD
    if len(sys.argv) > 2:
        sys.exit(f"usage: {Path(sys.argv[0]).name} [board directory name]")
    if len(sys.argv) == 2:
        BOARD = sys.argv[1]
    out_dir = HERE.parent / BOARD
    if not (out_dir / "board_specific_top.sv").is_file():
        sys.exit(f"{out_dir} is not a board directory")
    for variant in DACS:
        out = out_dir / f"breadboard_{variant}.svg"
        out.write_text(draw(variant), encoding="utf-8")
        print(f"wrote {out.relative_to(HERE.parent)}")


if __name__ == "__main__":
    main()
