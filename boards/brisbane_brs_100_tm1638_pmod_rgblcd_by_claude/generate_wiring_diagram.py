#!/usr/bin/env python3
"""Generate wiring.svg for brisbane_brs_100_tm1638_pmod_rgblcd_by_claude.

Run from any directory:

    python3 generate_wiring_diagram.py

and convert the result to PNG, for example with Inkscape:

    inkscape wiring.svg --export-type=png --export-dpi=96 \
        --export-background=white --export-filename=wiring.png

The pin data below must match board_specific.cst.
"""

from pathlib import Path
from xml.sax.saxutils import escape

OUT = Path(__file__).with_name("wiring.svg")

W, H = 1740, 1290
PITCH = 34

FONT = "DejaVu Sans, Liberation Sans, Arial, sans-serif"
MONO = "DejaVu Sans Mono, Liberation Mono, monospace"

C = {
    "R": "#d1495b",
    "G": "#3a9a4a",
    "B": "#3b6fd1",
    "SYNC": "#8e5bb5",
    "TM": "#c99100",
    "DAC": "#8c5a3c",
    "MIC": "#1a9a9a",
    "GPIO": "#777777",
    "3V3": "#ef7d1a",
    "5V": "#b0182a",
    "GND": "#222222",
    "board": "#1d4fa8",
    "board_edge": "#0f2e66",
    "pcb": "#232323",
    "text": "#1b1b1b",
    "muted": "#5b6170",
}

# BRS-100 header pins: (header, pin) -> (FPGA pin or rail, use).
# Rows 1..16 are GPIO, 17 is GND, 18 is +5V on J5 and +3.3V on J6.

J5 = {
    1: ("25", "TM1638 DIO"), 2: ("26", "TM1638 CLK"), 3: ("27", "TM1638 STB"),
    4: ("28", "DAC BCK"), 5: ("29", "DAC DIN"), 6: ("30", "DAC LCK"),
    7: ("33", "LCD DE"), 8: ("34", "LCD VS"), 9: ("35", "LCD CLK"),
    10: ("36", "MIC SCK"), 11: ("37", "MIC WS"), 12: ("38", "MIC L/R"),
    13: ("39", "MIC SD"), 14: ("40", "LCD HS"), 15: ("41", "B4"),
    16: ("42", "B3"), 17: ("GND", ""), 18: ("+5V", ""),
}

J6 = {
    1: ("77", "GPIO[0]"), 2: ("76", "GPIO[1]"), 3: ("75", "R0"),
    4: ("74", "R1"), 5: ("73", "R2"), 6: ("72", "R3"), 7: ("71", "R4"),
    8: ("70", "G0"), 9: ("69", "G1"), 10: ("68", "G2"), 11: ("57", "G3"),
    12: ("56", "G4"), 13: ("55", "G5"), 14: ("54", "B0"), 15: ("53", "B1"),
    16: ("51", "B2"), 17: ("GND", ""), 18: ("+3.3V", ""),
}

# PMOD-RGBLCD J2, component side, pin 1 is the square pad at the top left.
# The left column is 1..15 from the top, the right column is 30..16.

J2 = {
    1: "G0", 2: "G1", 3: "G2", 4: "G3", 5: "GND", 6: "3V3", 7: "G4",
    8: "GND", 9: "G5", 10: "LCD_CLK", 11: "LCD_HS", 12: "LCD_VS",
    13: "LCD_DE", 14: "GND", 15: "3V3",
    30: "R0", 29: "R1", 28: "R2", 27: "R3", 26: "GND", 25: "3V3",
    24: "R4", 23: "5V", 22: "B0", 21: "B1", 20: "B2", 19: "B3",
    18: "B4", 17: "GND", 16: "3V3",
}

svg = []


def add(s):
    svg.append(s)


def text(x, y, s, size=14, anchor="start", weight="normal", color=None,
         family=FONT, extra=""):
    color = color or C["text"]
    add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{family}" '
        f'font-size="{size}" font-weight="{weight}" fill="{color}" '
        f'text-anchor="{anchor}" dominant-baseline="central"{extra}>'
        f'{escape(s)}</text>')


def rect(x, y, w, h, fill, stroke="none", rx=0, sw=1.5, extra=""):
    add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" '
        f'rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{extra}/>')


def pin(x, y, square=False, fill="#e9c46a", stroke="#7a5c12"):
    if square:
        rect(x - 7, y - 7, 14, 14, fill, stroke, sw=1.5)
    else:
        add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="7" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="1.5"/>')


def wire(points, color, width=3.2):
    """An orthogonal wire with rounded corners through the given points."""
    r = 9
    d = f"M {points[0][0]:.1f} {points[0][1]:.1f}"

    for i in range(1, len(points) - 1):
        (x0, y0), (x1, y1), (x2, y2) = points[i - 1], points[i], points[i + 1]
        l1 = max(abs(x1 - x0), abs(y1 - y0))
        l2 = max(abs(x2 - x1), abs(y2 - y1))
        k = min(r, l1 / 2, l2 / 2)
        ax = x1 - k * ((x1 > x0) - (x1 < x0))
        ay = y1 - k * ((y1 > y0) - (y1 < y0))
        bx = x1 + k * ((x2 > x1) - (x2 < x1))
        by = y1 + k * ((y2 > y1) - (y2 < y1))
        d += f" L {ax:.1f} {ay:.1f} Q {x1:.1f} {y1:.1f} {bx:.1f} {by:.1f}"

    d += f" L {points[-1][0]:.1f} {points[-1][1]:.1f}"

    # A white halo makes crossings readable.
    add(f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="{width + 3}" '
        f'stroke-linecap="round" stroke-linejoin="round"/>')
    add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
        f'stroke-linecap="round" stroke-linejoin="round"/>')


def dot(x, y, color):
    add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4.5" fill="{color}"/>')


# ---------------------------------------------------------------------------
# Geometry

TOP = 350                           # y of header row 1

BRS_X0, BRS_X1 = 600, 880           # board outline
J5_X, J6_X = 628, 852               # header columns


def hy(row):
    return TOP + (row - 1) * PITCH


BRS_BOTTOM = hy(18) + 40

AD_X0, AD_X1 = 1210, 1480           # PMOD-RGBLCD outline
J2L_X, J2R_X = 1242, 1448           # J2 columns
AD_TOP = 310


def j2y(n):
    row = n if n <= 15 else 31 - n
    return AD_TOP + 40 + (row - 1) * PITCH


def j2x(n):
    return J2L_X if n <= 15 else J2R_X


AD_BOTTOM = j2y(15) + 34

RAIL_Y = {"3V3": 1150, "5V": 1190, "GND": 1230}
RAIL_X0, RAIL_X1 = 30, 1710

# ---------------------------------------------------------------------------

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
    f'viewBox="0 0 {W} {H}">')
add('<title>BRS-100-GW1NR9 wiring for brisbane_brs_100_tm1638_pmod_rgblcd_by_claude</title>')
rect(0, 0, W, H, "#ffffff")

text(40, 38, "BRS-100-GW1NR9 + PMOD-RGBLCD 4.3\" 480x272 + TM1638 + PCM5102 + INMP441",
     size=24, weight="bold")
text(40, 70, "Board configuration brisbane_brs_100_tm1638_pmod_rgblcd_by_claude. "
     "Each wire is one female-female jumper; both ends are labeled.",
     size=15, color=C["muted"])
text(40, 94, "The headers of BRS-100 and PMOD-RGBLCD are seen from the component "
     "side. BRS-100 labels give header pin and FPGA pin.",
     size=15, color=C["muted"])

# Legend

legend = [("R", "LCD red"), ("G", "LCD green"), ("B", "LCD blue"),
          ("SYNC", "LCD clock and sync"), ("TM", "TM1638"), ("DAC", "PCM5102"),
          ("MIC", "INMP441"), ("3V3", "+3.3 V"), ("5V", "+5 V"), ("GND", "GND")]
lx = 40

for key, label in legend:
    add(f'<line x1="{lx}" y1="132" x2="{lx + 28}" y2="132" stroke="{C[key]}" '
        f'stroke-width="5" stroke-linecap="round"/>')
    text(lx + 36, 132, label, size=13)
    lx += 52 + 8 * len(label)

# ---------------------------------------------------------------------------
# BRS-100 board

rect(BRS_X0, TOP - 90, BRS_X1 - BRS_X0, BRS_BOTTOM - TOP + 90, C["board"],
     C["board_edge"], rx=22, sw=3)
rect(700, TOP - 112, 80, 52, "#c9ced6", "#7c838f", rx=10, sw=2)
text(740, TOP - 86, "USB-C", size=12, anchor="middle", weight="bold")

for bx, label, loc in ((650, "Button 1", "pin 3, KEY[1]"),
                       (830, "Button 2", "pin 4, KEY[0]")):
    rect(bx - 15, TOP - 70, 30, 30, "#d9d9d9", "#555", rx=4)
    add(f'<circle cx="{bx}" cy="{TOP - 55}" r="8" fill="#444"/>')
    text(bx, TOP - 128, label, size=12, anchor="middle", weight="bold")
    text(bx, TOP - 112, loc, size=11, anchor="middle", color=C["muted"])

text(740, TOP + 6 * PITCH, "BRS-100", size=26, anchor="middle",
     weight="bold", color="#ffffff")
text(740, TOP + 6 * PITCH + 30, "GW1NR9", size=18, anchor="middle",
     color="#dbe6ff")
rect(690, TOP + 9 * PITCH, 100, 100, "#2b2b2b", "#111", rx=4)
text(740, TOP + 9 * PITCH + 50, "GW1NR-9", size=13, anchor="middle",
     color="#bbbbbb")
text(J5_X, TOP - 26, "J5", size=16, anchor="middle", weight="bold",
     color="#ffffff")
text(J6_X, TOP - 26, "J6", size=16, anchor="middle", weight="bold",
     color="#ffffff")

for header, x, table, side in (("J5", J5_X, J5, 1), ("J6", J6_X, J6, -1)):
    for row in range(1, 19):
        y = hy(row)
        loc, use = table[row]
        pin(x, y, square=(row == 1))
        label = f"{row:>2}  {loc}"
        text(x + side * 16, y, label, size=12, anchor="start" if side > 0 else "end",
             color="#ffffff", family=MONO)

# ---------------------------------------------------------------------------
# PMOD-RGBLCD

rect(AD_X0, AD_TOP - 40, AD_X1 - AD_X0, AD_BOTTOM - AD_TOP + 60, C["pcb"],
     "#000", rx=14, sw=2)
text((AD_X0 + AD_X1) / 2, AD_TOP - 14, "PMOD-RGBLCD v1.3, header J2", size=15,
     anchor="middle", weight="bold", color="#ffffff")
text((AD_X0 + AD_X1) / 2, AD_BOTTOM + 2, "LCD ribbon connector on this side →",
     size=12, anchor="middle", color="#bbbbbb")

for n, name in J2.items():
    x, y = j2x(n), j2y(n)
    pin(x, y, square=(n == 1), fill="#d9d9d9", stroke="#777")
    if n <= 15:
        text(x + 16, y, f"{n:>2} {name}", size=12, family=MONO, color="#ffffff")
    else:
        text(x - 16, y, f"{name} {n:>2}", size=12, anchor="end", family=MONO,
             color="#ffffff")

# ---------------------------------------------------------------------------
# Peripheral modules on the left

MOD_X0, MOD_X1 = 110, 330
MOD_PIN_X = MOD_X1 - 14


def module(title, subtitle, y0, pins, color):
    """Draws a module with pins on its right edge; returns pin y by name."""
    h = 54 + PITCH * len(pins)
    rect(MOD_X0, y0, MOD_X1 - MOD_X0, h, "#f4f1e8", "#8a8577", rx=10, sw=2)
    rect(MOD_X0, y0, 10, h, color, rx=0)
    text(MOD_X0 + 22, y0 + 18, title, size=15, weight="bold")
    text(MOD_X0 + 22, y0 + 38, subtitle, size=11, color=C["muted"])
    ys = {}

    for i, name in enumerate(pins):
        y = y0 + 54 + PITCH * i + PITCH / 2 - 6
        pin(MOD_PIN_X, y)
        text(MOD_PIN_X - 14, y, name, size=12, anchor="end", family=MONO)
        ys[name] = y

    return ys


tm = module("TM1638 LED&KEY", "8 digits, 8 LEDs, 8 keys", TOP - 66,
            ["DIO", "CLK", "STB", "GND", "VCC"], C["TM"])
dac = module("PCM5102 DAC", "I2S audio output", TOP + 180,
             ["BCK", "DIN", "LCK", "SCK", "GND", "VIN"], C["DAC"])
mic = module("INMP441", "I2S microphone", TOP + 460,
             ["SCK", "WS", "L/R", "SD", "VDD", "GND"], C["MIC"])

# ---------------------------------------------------------------------------
# Wires from the modules to J5, lanes between the modules and the board

def lane_left(i):
    return 360 + 18 * i


def to_j5(y_from, row, lane, color):
    wire([(MOD_PIN_X, y_from), (lane_left(lane), y_from),
          (lane_left(lane), hy(row)), (J5_X, hy(row))], color)


to_j5(tm["DIO"], 1, 0, C["TM"])
to_j5(tm["CLK"], 2, 1, C["TM"])
to_j5(tm["STB"], 3, 2, C["TM"])

to_j5(dac["BCK"], 4, 0, C["DAC"])
to_j5(dac["DIN"], 5, 1, C["DAC"])
to_j5(dac["LCK"], 6, 2, C["DAC"])

to_j5(mic["SCK"], 10, 0, C["MIC"])
to_j5(mic["WS"], 11, 1, C["MIC"])
to_j5(mic["L/R"], 12, 2, C["MIC"])
to_j5(mic["SD"], 13, 3, C["MIC"])

# Module power goes around the left side of the modules down to the rails.
# The lower a module, the closer to the modules its lanes are,
# and the lower pin of a module takes the inner lane,
# so that the power wires do not cross.


def module_bottom(ys):
    return max(ys.values()) + PITCH / 2 + 6


def power(ys, name, rail, j, x_left):
    """j orders the wires of a module: 0 is the inner one at the module."""
    color = C["GND"] if rail == "GND" else C[rail]
    x_side = MOD_X1 + 10 + 9 * j
    y_below = module_bottom(ys) + 12 + 9 * j
    wire([(MOD_PIN_X, ys[name]), (x_side, ys[name]), (x_side, y_below),
          (x_left, y_below), (x_left, RAIL_Y[rail])], color)
    dot(x_left, RAIL_Y[rail], color)
    return x_side, y_below


power(tm, "VCC", "3V3", 0, 44)
power(tm, "GND", "GND", 1, 54)

power(dac, "VIN", "3V3", 0, 64)
x_gnd, _ = power(dac, "GND", "GND", 1, 74)

# PCM5102 SCK joins the GND wire of the module

wire([(MOD_PIN_X, dac["SCK"]), (x_gnd, dac["SCK"]), (x_gnd, dac["GND"])], C["GND"])
dot(x_gnd, dac["GND"], C["GND"])

power(mic, "GND", "GND", 0, 84)
power(mic, "VDD", "3V3", 1, 94)

# ---------------------------------------------------------------------------
# J6 to the left column of J2: the green bits go straight across

GREEN_X = [1060 - 16 * k for k in range(6)]

for k, (row, n) in enumerate(((8, 1), (9, 2), (10, 3), (11, 4), (12, 7), (13, 9))):
    wire([(J6_X, hy(row)), (GREEN_X[k], hy(row)),
          (GREEN_X[k], j2y(n)), (J2L_X, j2y(n))], C["G"])

# J6 to the right column of J2. The adapter numbers the right column
# upwards, so these wires go around the adapter and cross each other.
# Red goes over the top, blue under the bottom.

for k, (row, n) in enumerate(((3, 30), (4, 29), (5, 28), (6, 27), (7, 24))):
    x_out = 900 + 14 * k
    y_top = AD_TOP - 66 - 12 * k
    x_in = 1510 + 16 * k
    wire([(J6_X, hy(row)), (x_out, hy(row)), (x_out, y_top),
          (x_in, y_top), (x_in, j2y(n)), (J2R_X, j2y(n))], C["R"])

UNDER_Y = AD_BOTTOM + 60

for k, (row, n) in enumerate(((14, 22), (15, 21), (16, 20))):
    x_out = 1080 + 14 * k
    y_low = UNDER_Y + 14 * k
    x_in = 1640 - 16 * k
    wire([(J6_X, hy(row)), (x_out, hy(row)), (x_out, y_low),
          (x_in, y_low), (x_in, j2y(n)), (J2R_X, j2y(n))], C["B"])

# J5 to J2: under the BRS-100, then up into the adapter

BOTTOM_LANE = BRS_BOTTOM + 30

from_j5 = [(7, 13, "SYNC"), (8, 12, "SYNC"), (9, 10, "SYNC"), (14, 11, "SYNC"),
           (15, 18, "B"), (16, 19, "B")]

for k, (row, n, ch) in enumerate(from_j5):
    x_out = 590 - 8 * k
    y_low = BOTTOM_LANE + 14 * k

    if n <= 15:
        x_in = 1124 + 14 * k
        wire([(J5_X, hy(row)), (x_out, hy(row)), (x_out, y_low),
              (x_in, y_low), (x_in, j2y(n)), (J2L_X, j2y(n))], C[ch])
    else:
        x_in = 1580 - 16 * (k - 4)
        wire([(J5_X, hy(row)), (x_out, hy(row)), (x_out, y_low),
              (x_in, y_low), (x_in, j2y(n)), (J2R_X, j2y(n))], C[ch])

# ---------------------------------------------------------------------------
# Power rails

for rail, label in (("3V3", "+3.3 V rail"), ("5V", "+5 V rail"), ("GND", "GND rail")):
    color = C["GND"] if rail == "GND" else C[rail]
    add(f'<line x1="{RAIL_X0}" y1="{RAIL_Y[rail]}" x2="{RAIL_X1}" '
        f'y2="{RAIL_Y[rail]}" stroke="{color}" stroke-width="7" '
        f'stroke-linecap="round"/>')
    text(RAIL_X0 + 80, RAIL_Y[rail] - 14, label, size=13, weight="bold", color=color)

# BRS-100 power pins

wire([(J5_X, hy(17)), (610, hy(17)), (610, RAIL_Y["GND"])], C["GND"])
dot(610, RAIL_Y["GND"], C["GND"])
wire([(J5_X, hy(18)), (618, hy(18)), (618, RAIL_Y["5V"])], C["5V"])
dot(618, RAIL_Y["5V"], C["5V"])
wire([(J6_X, hy(17)), (900, hy(17)), (900, RAIL_Y["GND"])], C["GND"])
dot(900, RAIL_Y["GND"], C["GND"])
wire([(J6_X, hy(18)), (888, hy(18)), (888, RAIL_Y["3V3"])], C["3V3"])
dot(888, RAIL_Y["3V3"], C["3V3"])

# PMOD-RGBLCD power pins

wire([(J2L_X, j2y(15)), (1206, j2y(15)), (1206, RAIL_Y["3V3"])], C["3V3"])
dot(1206, RAIL_Y["3V3"], C["3V3"])
wire([(J2L_X, j2y(14)), (1194, j2y(14)), (1194, RAIL_Y["GND"])], C["GND"])
dot(1194, RAIL_Y["GND"], C["GND"])
wire([(J2R_X, j2y(17)), (1690, j2y(17)), (1690, RAIL_Y["GND"])], C["GND"])
dot(1690, RAIL_Y["GND"], C["GND"])
wire([(J2R_X, j2y(23)), (1676, j2y(23)), (1676, RAIL_Y["5V"])], C["5V"])
dot(1676, RAIL_Y["5V"], C["5V"])

# Notes

text(40, H - 22, "J6 pins 1 and 2 (FPGA pins 77 and 76) stay free as user GPIO. "
     "PCM5102: SCK to GND; solder jumpers "
     "FLT, DEMP, FMT low and XSMT high.", size=13, color=C["muted"])

add("</svg>")
OUT.write_text("\n".join(svg) + "\n")
print(f"Wrote {OUT}")
