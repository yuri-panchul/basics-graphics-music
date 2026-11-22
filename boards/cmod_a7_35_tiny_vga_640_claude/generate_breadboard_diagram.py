#!/usr/bin/env python3
"""Generate the breadboard layouts of the board configuration
cmod_a7_35_tiny_vga_640_claude.

Unlike the wiring diagrams of generate_wiring_diagram.py, these drawings show
the holes of a full-size breadboard, with the INMP441 microphone, the DAC
module and the 3.3 V regulator of variant B plugged straight into it. Run from
any directory:

    python3 generate_breadboard_diagram.py

The other five Cmod A7 configurations share this wiring and use the
drawings of this directory; those without TM1638 leave out the module
and its wires.

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

from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent
BOARD = "cmod_a7_35_tiny_vga_640_claude"  # the name in the drawings

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
BX, BY = 360, 200  # position of row 1, rail TO
W = 2000


def X(row):
    return BX + (row - 1) * P


def Y(u):
    if isinstance(u, str):
        u = U[u]
    return BY + u * P


def xy(row, u):
    return X(row), Y(u)


# Cmod A7 sits across the channel at the end of the breadboard, with DIP
# pins 24 and 25, VU and GND, in row 63, the last one: the USB plug is off
# the end of the breadboard, and the USB cable leaves it. Pins 25 to 48 are
# in column c, two holes from the channel, and pins 1 to 24 in column g, one
# hole from it; row r holds DIP pins 88 - r and r - 39. This leaves holes a
# and b free on one side and h, i and j on the other. TinyVGA, in the Pmod
# socket at the other end, lies over the breadboard, its VGA socket facing
# up, and the modules go in the rows beyond it.

CMOD_TOP, CMOD_BOT = "c", "g"
CMOD_ROW = 40  # the row of DIP pins 1 and 48


def dip(pin):
    """The breadboard position of a DIP pin of Cmod A7."""
    if pin <= 24:
        return CMOD_ROW - 1 + pin, CMOD_BOT
    return CMOD_ROW + 48 - pin, CMOD_TOP


CMOD_NAMES = {12: "STB", 13: "CLK", 14: "DIO", 17: "SCK", 18: "WS", 19: "L/R", 20: "SD",
              21: "BCK", 22: "DIN", 23: "LCK", 24: "VU", 25: "GND"}
CMOD_FREE = (19,)  # DIP 19 stays free: INMP441 L/R goes to GND here

# The 3.3 V regulator of variant B: a 3-pin AMS1117-3.3 module, Amazon
# B08CDMZMDN, about 8.6 x 12.3 mm. A photo of the module shows its pins
# labeled VIN, OUT and GND, in this order, on a right-angle header whose
# plastic sits on the labeled side, and a power LED. It stands on its header
# in column j, away from Cmod A7, its labels toward the channel: GND, OUT
# and VIN in rows 4, 5 and 6. Its board stands over the gap between column
# j and the bottom rails, so hole i stays free. One wire brings VIN 5 V from
# DIP 24, VU.

REG_ROW = 4
REG_PINS = ["GND", "OUT", "VIN"]
REG_MARGIN = 0.69  # from the outer pins to the board edges, in pitches
REG_HEADER = 1.0   # the plastic of the header across the pins, in pitches
REG_PCB = 0.63     # the board, 1.6 mm thick, next to the plastic

# INMP441 sits across the channel like a 6-pin DIP chip: its two rows of
# three pins are 0.3 inch apart, in columns e and f. It is turned so that
# SCK, the pin nearest to Cmod A7, and WS are in the strips that the wires
# from Cmod A7 reach without crossing the channel.

MIC_ROW = 19
MIC_TOP = ["GND", "VDD", "SD"]   # column e, rows MIC_ROW to MIC_ROW + 2
MIC_BOT = ["L/R", "WS", "SCK"]   # column f, SCK opposite SD

# The DAC modules go in by their header, in column j, with the module body
# and the headphone jack hanging over the rails and the edge of the
# breadboard. "body" is (rows before the first pin, rows after the last pin,
# depth beyond column j), in pitches. "end" is the hole where the wires from
# Cmod A7 end: below the lanes of the wires for WeAct, above them for
# GY-PCM5102, whose pins come in the other order.

DACS = {
    "weact": {
        "title": "WeAct I2S Earphone Module V1",
        "subtitle": "PCM5100A; 28.0 x 18.2 mm",
        "short": "WeAct PCM5100A",
        "row": 9,
        "pins": ["WS", "DIN", "BCK", "MC", "/SD", "GND", "VCC"],
        "end": "i",
        "body": (0.6, 0.6, 10.4),
        "exact": True,
        "power": "VCC",
        "nc": ["MC", "/SD"],
        "notes": ["WeAct: /SD and MC stay unconnected; the module pulls /SD up and MC down.",
                  "Put the module in label side up, its jack toward the edge of the breadboard: "
                  "WS goes in row 9 and VCC in row 15."],
    },
    "gy_pcm5102": {
        "title": "GY-PCM5102",
        "subtitle": "PCM5102A; outline approximate",
        "short": "GY-PCM5102",
        "row": 9,
        "pins": ["SCK", "BCK", "DIN", "LCK", "GND", "VIN"],
        "end": "g",
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

# The wires from Cmod A7 to the modules leave the strips of DIP 17 to 24 by
# hole j and run left in lanes over hole row h, so that holes i and j of the
# GPIO strips stay free. A wire from a pin further right takes a lane
# further up and goes further left, so that the wires do not cross on their
# way; only SD of INMP441 crosses the lanes of the DAC and the regulator,
# to reach the other side of the channel.

LANES = {24: 11.75, 23: 11.95, 22: 12.15, 21: 12.35, 20: 12.55, 18: 12.75, 17: 12.95}


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


def lane_wire(svg, dip_pin, row1, u1, color):
    """From hole j of the strip of a DIP pin up to its lane, left along the
    lane and into hole u1 of row row1."""
    r0 = dip(dip_pin)[0]
    lane = Y(LANES[dip_pin])
    x0, y0 = xy(r0, "j")
    x1, y1 = xy(row1, u1)
    d = (f"M{x0:.1f},{y0:.1f} C{x0:.1f},{lane:.1f} {x0:.1f},{lane:.1f} {x0 - 0.5 * P:.1f},{lane:.1f} "
         f"L{x1 + 0.5 * P:.1f},{lane:.1f} C{x1:.1f},{lane:.1f} {x1:.1f},{lane:.1f} {x1:.1f},{y1:.1f}")
    svg.wire(d, color, 3)
    wire_end(svg, r0, "j", color)
    wire_end(svg, row1, u1, color)


def draw(variant):
    dac = DACS[variant]
    svg = Svg()

    # Title and notes on top

    svg.text(40, 46, f"Breadboard layout: Cmod A7-35T, INMP441, {dac['short']} "
                     f"and the 3.3 V regulator", 26, "bold")
    svg.text(40, 76, f"Board configuration {BOARD}, seen from above. Cmod A7 is at the end of "
                     "the breadboard, its USB plug off the end; the microphone, the DAC and the "
                     "3.3 V regulator of variant B go into the free rows.", 15, fill=C["muted"])
    svg.text(40, 98, "Tinted holes are the strips in use: the five holes of a strip are "
                     "connected. A dot is a jumper wire in a hole.", 15, fill=C["muted"])
    legend = [("TM1638", C["TM"]), ("INMP441", C["MIC"]), ("DAC", C["DAC"]),
              ("+3.3 V", C["3V3"]), ("GND", C["GND"]), ("+5 V (VU)", C["5V"])]
    x = 40
    for label, color in legend:
        svg.line(x, 128, x + 30, 128, color, 5)
        svg.text(x + 38, 133, label, 14)
        x += 125
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
        svg.text(X(1) - 0.8 * P, Y(col) + 4, col, 11, fill=C["muted"], anchor="middle",
                 family=MONO)
    for rail, name in RAILS.items():
        color = C["3V3"] if name.startswith("+") else C["GND"]
        svg.text(X(1) - 0.8 * P, Y(rail) + 4, "+" if name.startswith("+") else "−", 13,
                 "bold", color, "middle")

    # Tint the strips in use

    tints = [(dip(25)[0], True, C["GND"]), (dip(24)[0], False, C["5V"])]
    tints += [(dip(p)[0], False, C["DAC"]) for p in (21, 22, 23)]
    tints += [(dip(p)[0], False, C["MIC"]) for p in (17, 18, 20)]
    tints += [(dip(p)[0], False, C["TM"]) for p in (12, 13, 14)]
    for k, name in enumerate(REG_PINS):
        tints.append((REG_ROW + k, False, {"VIN": C["5V"], "GND": C["GND"],
                                           "OUT": C["3V3"]}[name]))
    tint_of = {"GND": C["GND"], "L/R": C["GND"], "VDD": C["3V3"]}
    for k in range(3):
        tints.append((MIC_ROW + k, True, tint_of.get(MIC_TOP[k], C["MIC"])))
        tints.append((MIC_ROW + k, False, tint_of.get(MIC_BOT[k], C["MIC"])))
    for k, name in enumerate(dac["pins"]):
        if name in dac["nc"]:
            continue
        color = (C["3V3"] if name == dac["power"] else
                 C["GND"] if name in ("GND", "SCK") else C["DAC"])
        tints.append((dac["row"] + k, False, color))
    for row, top, color in tints:
        strip(svg, row, top, color)

    # Cmod A7, its USB plug off the end of the breadboard

    cx0, cx1 = X(CMOD_ROW) - 3.5 * P, X(ROWS) + 0.9 * P
    cy0, cy1 = Y(CMOD_TOP) - 0.5 * P, Y(CMOD_BOT) + 0.5 * P
    cmid = (U[CMOD_TOP] + U[CMOD_BOT]) / 2
    svg.line(cx1 + 1.0 * P, Y(cmid), W - 10, Y(cmid), "#7d828c", 12)
    svg.text(W - 14, Y(cmid) - 14, "USB cable", 12, "bold", C["muted"], "end")
    svg.rect(cx0, cy0, cx1 - cx0, cy1 - cy0, C["board"], C["board_edge"], 2, 6)
    svg.rect(cx1 - 6, Y(cmid) - 0.95 * P, 1.1 * P, 1.9 * P, "#c9ccd2", "#7d828c", 1.5, 3)
    svg.text(cx1 + 0.45 * P - 6, Y(cmid) + 4, "USB", 10, "bold", anchor="middle")
    svg.rect(X(CMOD_ROW + 2), Y(cmid - 1.2), 3.6 * P, 1.7 * P, "#202020", "#000000", 1, 3)
    svg.text(X(CMOD_ROW + 2) + 1.8 * P, Y(cmid - 0.35) + 4, "XC7A35T", 11, fill="#d8d8d8",
             anchor="middle")
    svg.text(X(CMOD_ROW + 12), Y(cmid) + 2, "Cmod A7-35T", 22, "bold", "#ffffff", "middle")
    svg.text(X(CMOD_ROW + 12), Y(cmid) + 20, "pins 48..25 in column c, 1..24 in column g", 10,
             fill="#c7d3e6", anchor="middle")
    for pin in range(1, 49):
        row, col = dip(pin)
        x, y = xy(row, col)
        svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
        ny = y + 17 if col == CMOD_TOP else y - 10
        svg.text(x, ny, str(pin), 9, fill="#ffffff", anchor="middle", family=MONO)
        if pin in CMOD_NAMES:
            color = "#9fb2cf" if pin in CMOD_FREE else "#ffe08a"
            if col == CMOD_TOP:
                svg.text(x + 3.5, y + 24, CMOD_NAMES[pin], 9, "bold", color, "end", MONO, rotate=-90)
            else:
                svg.text(x + 3.5, y - 20, CMOD_NAMES[pin], 9, "bold", color, "start", MONO, rotate=-90)

    # The GPIO pins of the labs; nothing is connected to them. They start at
    # DIP 48 and run down the top row, then go on from DIP 1.

    for first, last, label in ((48, 26, "GPIO 0 to 22"), (1, 11, "GPIO 23 to 33")):
        (x0, y0), (x1, _) = xy(*dip(first)), xy(*dip(last))
        gy = y0 + 31 if dip(first)[1] == CMOD_TOP else y0 - 22
        svg.text((x0 + x1) / 2, gy, label, 9, "bold", "#9fb2cf", "middle", MONO)

    # Pmod JA and TinyVGA, which lies over the breadboard

    svg.rect(cx0 - 0.9 * P, Y(cmid - 2.5), 1.0 * P, 5 * P, "#2a2a2a", "#000000", 1, 3)
    svg.text(cx0 - 0.4 * P, Y(cmid + 2.5) + 16, "JA", 11, "bold", anchor="middle")
    tv1 = cx0 - 0.9 * P
    tv0 = tv1 - 190
    svg.rect(tv0, Y(cmid) - 75, 190, 150, "#2b2b2b", "#000000", 1.5, 6, opacity=0.93)
    svg.rect(tv0 + 20, Y(cmid) - 40, 80, 34, "#4a4f57", "#000000", 1, 4)
    svg.text(tv0 + 60, Y(cmid) - 18, "VGA, up", 11, "bold", "#ffffff", "middle")
    svg.text(tv0 + 95, Y(cmid) - 52, "TinyVGA", 17, "bold", "#ffffff", "middle")
    for k, s in enumerate(("over the breadboard;", "in variant A", "through Pmod TPH2")):
        svg.text(tv0 + 95, Y(cmid) + 18 + 18 * k, s, 12, fill="#d0d0d0", anchor="middle")

    # TM1638, off the breadboard below it, and its wires

    tm_y = Y("BO") + 3.4 * P
    first = dip(12)[0] - 2
    tm_pins = [("VCC", first), ("GND", first + 1), ("STB", first + 2), ("CLK", first + 3),
               ("DIO", first + 4)]
    tx0, tx1 = X(first - 9), X(first + 12)
    svg.rect(tx0, tm_y, tx1 - tx0, 3.6 * P, "#f3f1ea", "#8a8577", 1.5, 6)
    svg.rect(tx0, tm_y + 3.6 * P - 10, tx1 - tx0, 10, C["TM"], rx=3)
    svg.text(tx0 + 16, tm_y + 1.35 * P, "TM1638 LED&KEY,", 14, "bold")
    svg.text(tx0 + 16, tm_y + 2.15 * P, "off the breadboard, on", 11, fill=C["muted"])
    svg.text(tx0 + 16, tm_y + 2.75 * P, "female-to-male wires", 11, fill=C["muted"])
    for name, row in tm_pins:
        svg.circle(X(row), tm_y, 5, "#f2c14e", "#5c4a12", 1)
        svg.text(X(row), tm_y + 18, name, 9, "bold", anchor="middle", family=MONO)
    for (name, row), dip_pin in zip(tm_pins[2:], (12, 13, 14)):
        svg.wire(f"M{X(row):.1f},{Y('j'):.1f} L{X(row):.1f},{tm_y:.1f}", C["TM"])
        wire_end(svg, row, "j", C["TM"])
    for (name, row), rail, color in ((tm_pins[0], "BI", C["3V3"]), (tm_pins[1], "BO", C["GND"])):
        svg.wire(f"M{X(row):.1f},{Y(rail):.1f} L{X(row):.1f},{tm_y:.1f}", color)
        wire_end(svg, row, rail, color)

    # DIP 25, GND, to the top GND rail

    r25 = dip(25)[0]
    svg.wire(path([(r25, "a"), (r25, "TI")]), C["GND"])
    wire_end(svg, r25, "a", C["GND"])
    wire_end(svg, r25, "TI", C["GND"])

    # The regulator, standing on its header in column j, its labels toward
    # the channel. Seen from above: the plastic of the header over the pins
    # and the edge of its board beyond them. The board stands between column
    # j and the bottom rails, so GND and OUT go to the top rails.

    reg_row = {name: REG_ROW + k for k, name in enumerate(REG_PINS)}
    r_first, r_last = REG_ROW, REG_ROW + len(REG_PINS) - 1
    hy0 = Y("j") - REG_HEADER / 2 * P
    svg.rect(X(r_first - 0.5), hy0, X(r_last + 0.5) - X(r_first - 0.5), REG_HEADER * P,
             "#2a2a2a", "#000000", 1, 2, opacity=0.9)
    rx0, rx1 = X(r_first - REG_MARGIN), X(r_last + REG_MARGIN)
    py0 = hy0 + REG_HEADER * P
    svg.rect(rx0, py0, rx1 - rx0, REG_PCB * P, "#2f5fb0", "#173a73", 1, 1)
    for name, row in reg_row.items():
        x, y = xy(row, "j")
        svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
        svg.text(x, py0 + REG_PCB * P / 2 + 3.2, name, 9, "bold", "#ffffff", "middle", MONO)
    for name, rail, color in (("GND", "TI", C["GND"]), ("OUT", "TO", C["3V3"])):
        r = reg_row[name]
        svg.wire(path([(r, "f"), (r, rail)]), color)
        wire_end(svg, r, "f", color)
        wire_end(svg, r, rail, color)
    ry1 = Y("j") + 4.35 * P
    svg.text(rx1, ry1 + 18, "3.3 V regulator, AMS1117-3.3 module,", 12, "bold", anchor="end")
    svg.text(rx1, ry1 + 34, "standing on its header, labels toward", 11, fill=C["muted"],
             anchor="end")
    svg.text(rx1, ry1 + 49, "the channel: GND, OUT, VIN in rows 4 to 6", 11, fill=C["muted"],
             anchor="end")

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

    # DAC power, and SCK of GY-PCM5102, to the top rails: the module covers
    # the bottom rails next to it.

    pin_row = {name: row0 + k for k, name in enumerate(dac["pins"])}
    power = [("GND", "TI", C["GND"]), (dac["power"], "TO", C["3V3"])]
    if "SCK" in pin_row:
        power.append(("SCK", "TI", C["GND"]))
    for name, rail, color in power:
        r = pin_row[name]
        svg.wire(path([(r, "f"), (r, rail)]), color)
        wire_end(svg, r, "f", color)
        wire_end(svg, r, rail, color)

    # INMP441, across the channel

    mx, my = X(MIC_ROW + 1), Y(CHANNEL)
    svg.circle(mx, my, 2.75 * P, "#1c1c1c", "#c58b3a", 3, opacity=0.93)
    for k in range(3):
        for col, names, ly in (("e", MIC_TOP, 0.85), ("f", MIC_BOT, -0.6)):
            x, y = xy(MIC_ROW + k, col)
            svg.circle(x, y, 5.5, "#f2c14e", "#5c4a12", 1)
            svg.text(x, y + ly * P, names[k], 9, "bold", "#ffffff", "middle", MONO)
    svg.text(mx, my + 4, "INMP441", 10, "bold", "#d8d8d8", "middle")
    svg.text(X(MIC_ROW + 5.4), Y(CHANNEL) - 3, "INMP441,", 11, "bold")
    svg.text(X(MIC_ROW + 5.4), Y(CHANNEL) + 11, "label side up", 11, fill=C["muted"])

    # INMP441 power and L/R

    top = {name: MIC_ROW + k for k, name in enumerate(MIC_TOP)}
    bot = {name: MIC_ROW + k for k, name in enumerate(MIC_BOT)}
    for name, rail, color in (("GND", "TI", C["GND"]), ("VDD", "TO", C["3V3"])):
        svg.wire(path([(top[name], "a"), (top[name], rail)]), color)
        wire_end(svg, top[name], "a", color)
        wire_end(svg, top[name], rail, color)
    svg.wire(path([(bot["L/R"], "j"), (bot["L/R"], "BO")]), C["GND"])
    wire_end(svg, bot["L/R"], "j", C["GND"])
    wire_end(svg, bot["L/R"], "BO", C["GND"])

    # Cmod A7 to the modules, along the lanes. SD goes up through the
    # channel just past the microphone, over the other lanes, and back to
    # its strip on the far side.

    dac_end = dac["end"]
    lck = "WS" if "WS" in pin_row else "LCK"
    lane_wire(svg, 24, reg_row["VIN"], "i", C["5V"])
    for dip_pin, name in ((23, lck), (22, "DIN"), (21, "BCK")):
        lane_wire(svg, dip_pin, pin_row[name], dac_end, C["DAC"])
    lane_wire(svg, 18, bot["WS"], "i", C["MIC"])
    lane_wire(svg, 17, bot["SCK"], "i", C["MIC"])

    r0 = dip(20)[0]
    lane = LANES[20]
    sd_row = top["SD"]
    turn = MIC_ROW + 4.6
    d = path([(r0, "j"), (r0, lane), (r0, lane), (r0 - 0.5, lane)])
    d += (f" L{X(turn + 0.6):.1f},{Y(lane):.1f}"
          f" C{X(turn):.1f},{Y(lane):.1f} {X(turn):.1f},{Y('b'):.1f} {X(turn - 1.0):.1f},{Y('b'):.1f}"
          f" L{X(sd_row):.1f},{Y('b'):.1f}")
    svg.wire(d, C["MIC"], 3)
    wire_end(svg, r0, "j", C["MIC"])
    wire_end(svg, sd_row, "b", C["MIC"])

    # Join the + rails and the GND rails at the far end of the breadboard

    d = path([(1, "TO"), (1 - 3.2, 3.0), (1 - 3.2, 13.0), (1, "BI")])
    svg.wire(d, C["3V3"])
    wire_end(svg, 1, "TO", C["3V3"])
    wire_end(svg, 1, "BI", C["3V3"])
    d = path([(2, "TI"), (2 - 4.6, 2.0), (2 - 4.6, 15.0), (2, "BO")])
    svg.wire(d, C["GND"])
    wire_end(svg, 2, "TI", C["GND"])
    wire_end(svg, 2, "BO", C["GND"])

    # Labels of the rails

    svg.text(X(1) - 1.0 * P, Y("TO") - 0.75 * P, "+3.3 V from the regulator (variant A: from TPH2). "
             "Both + rails and both GND rails are joined at this end.", 11, "bold", C["3V3"])

    # Notes

    notes = [f"Cmod A7 goes in rows {CMOD_ROW} to 63, DIP 25 to 48 in column c and 1 to 24 in "
             "column g, so that DIP 24 and 25, VU and GND, are in row 63, the last one: the USB "
             "plug is off the end of the breadboard.",
             "TinyVGA lies over rows 28 to 39, its VGA socket facing up; in variant A, Pmod TPH2 "
             "between JA and TinyVGA takes about 8 rows more. Keep rows 23 to 39 free of modules.",
             "The wires from DIP 17 to 24 leave their strips by hole j and run left over hole row h "
             "to the modules: holes i and j of the GPIO strips stay free. SD crosses the channel "
             "past the microphone.",
             "TM1638 is off the breadboard, on female-to-male wires: STB, CLK and DIO from hole j "
             "of rows 51 to 53, VCC and GND from the bottom rails.",
             "INMP441 goes across the center channel like a 6-pin DIP chip: L/R, WS, SCK in "
             "column f, GND, VDD, SD in column e. L/R goes to GND here, so DIP 19 stays free.",
             "The DAC goes in by its header in column j; its body and jack hang over the bottom "
             "rails and the edge of the breadboard, so it takes its power from the top rails.",
             "The regulator of variant B, an AMS1117-3.3 module, Amazon B08CDMZMDN, stands on its "
             "header in column j, labels toward the channel: GND, OUT, VIN in rows 4, 5, 6. OUT is "
             "the middle pin. The one red wire brings VIN 5 V from DIP 24, VU.",
             "Variant A, Pmod TPH2: leave the regulator and its 5 V wire out, and wire test point 6 "
             "of TPH2 to the + rail. Unplug USB before changing the wiring.",
             "DIP 48 to 26 and 1 to 11 are the GPIO pins of the labs, gpio[0] to gpio[33]; nothing "
             "is connected to them here."] + dac["notes"]
    ny = tm_y + 3.6 * P + 60
    for k, s in enumerate(notes):
        svg.text(40, ny + 20 * k, s, 13, fill=C["muted"])

    return svg.svg(int(ny + 20 * len(notes) + 8))


def main():
    for variant in DACS:
        out = HERE / f"breadboard_{variant}.svg"
        out.write_text(draw(variant), encoding="utf-8")
        print(f"wrote {out.relative_to(HERE.parent)}")


if __name__ == "__main__":
    main()
