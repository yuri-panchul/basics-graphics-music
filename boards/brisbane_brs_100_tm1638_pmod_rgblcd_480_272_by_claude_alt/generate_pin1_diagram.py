#!/usr/bin/env python3
"""Generate pmod_rgblcd_pin1.svg: where pin 1 of PMOD-RGBLCD J2 is.

Run from any directory:

    python3 generate_pin1_diagram.py

and convert the result to PNG, for example with Inkscape:

    inkscape pmod_rgblcd_pin1.svg --export-type=png --export-dpi=96 \
        --export-background=white --export-filename=pmod_rgblcd_pin1.png

The positions in millimeters are measured from the board drawing on page 2
of https://github.com/wuxx/icesugar/blob/master/schematic/pmod-rgblcd-v1.3.pdf
"""

from pathlib import Path
from xml.sax.saxutils import escape

OUT = Path(__file__).with_name("pmod_rgblcd_pin1.svg")

W, H = 1480, 950
MM = 11.5                       # pixels per millimeter

FONT = "DejaVu Sans, Liberation Sans, Arial, sans-serif"
MONO = "DejaVu Sans Mono, Liberation Mono, monospace"

INK = "#1b1b1b"
MUTED = "#5b6170"
PCB = "#232323"
SILK = "#e8e8e8"
COPPER = "#d9b45a"
PIN1 = "#d1203a"
GND = "#4a8f5a"
V33 = "#ef7d1a"
V5 = "#b0182a"

# Board outline and features, in mm from the top left corner of the
# component side, with the header J2 on the left edge.

BOARD_W, BOARD_H = 38.82, 40.0
COL_OUTER, COL_INNER = 3.9, 6.5            # x of the two J2 columns
ROW1, PITCH = 2.1, 2.54                    # y of row 1, row pitch
FPC = (28.3, 7.2, 33.9, 33.3)              # LCD ribbon connector
BOOST = (13.0, 3.0, 25.5, 13.0)            # U1, L1, D1, C2, C3, R1, R2
R3_Y, R4_Y = 17.9, 20.7

J2 = {
    1: "G0", 2: "G1", 3: "G2", 4: "G3", 5: "GND", 6: "3V3", 7: "G4",
    8: "GND", 9: "G5", 10: "LCD_CLK", 11: "LCD_HS", 12: "LCD_VS",
    13: "LCD_DE", 14: "GND", 15: "3V3",
    30: "R0", 29: "R1", 28: "R2", 27: "R3", 26: "GND", 25: "3V3",
    24: "R4", 23: "5V", 22: "B0", 21: "B1", 20: "B2", 19: "B3",
    18: "B4", 17: "GND", 16: "3V3",
}


def row_of(n):
    return n if n <= 15 else 31 - n


def color_of(name):
    return {"GND": GND, "3V3": V33, "5V": V5}.get(name)


svg = []


def add(s):
    svg.append(s)


def text(x, y, s, size=14, anchor="start", weight="normal", color=INK,
         family=FONT):
    add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{family}" '
        f'font-size="{size}" font-weight="{weight}" fill="{color}" '
        f'text-anchor="{anchor}" dominant-baseline="central">{escape(s)}</text>')


def board(ox, oy, mirrored, title, subtitle):
    """Draws one view of the board; ox, oy is the top left of the outline."""

    def X(mm):
        return ox + MM * (BOARD_W - mm if mirrored else mm)

    def Y(mm):
        return oy + MM * mm

    text(ox + MM * BOARD_W / 2, oy - 78, title, size=19, anchor="middle",
         weight="bold")
    text(ox + MM * BOARD_W / 2, oy - 54, subtitle, size=13, anchor="middle",
         color=MUTED)

    # Outline: square corners on the header edge, rounded on the other edge

    r = 2.5 * MM
    w, h = MM * BOARD_W, MM * BOARD_H

    if not mirrored:
        d = (f"M {ox} {oy} H {ox + w - r} Q {ox + w} {oy} {ox + w} {oy + r} "
             f"V {oy + h - r} Q {ox + w} {oy + h} {ox + w - r} {oy + h} "
             f"H {ox} Z")
    else:
        d = (f"M {ox + w} {oy} H {ox + r} Q {ox} {oy} {ox} {oy + r} "
             f"V {oy + h - r} Q {ox} {oy + h} {ox + r} {oy + h} "
             f"H {ox + w} Z")

    add(f'<path d="{d}" fill="{PCB}" stroke="#000" stroke-width="2"/>')

    # Component side features; on the bottom view only as dashed ghosts

    def box(x0, y0, x1, y1, label, dashed=False):
        xa, xb = sorted((X(x0), X(x1)))
        style = ('fill="none" stroke="#9a9a9a" stroke-dasharray="6 4"' if dashed
                 else f'fill="none" stroke="{SILK}"')
        add(f'<rect x="{xa:.1f}" y="{Y(y0):.1f}" width="{xb - xa:.1f}" '
            f'height="{Y(y1) - Y(y0):.1f}" rx="3" {style} stroke-width="1.6"/>')
        text((xa + xb) / 2, (Y(y0) + Y(y1)) / 2, label, size=12,
             anchor="middle", color="#9a9a9a" if dashed else SILK)

    if not mirrored:
        box(*FPC, "J1")
        text((X(FPC[0]) + X(FPC[2])) / 2, Y(FPC[3]) + 14, "LCD ribbon connector",
             size=11, anchor="middle", color=SILK)
        box(*BOOST, "U1 L1 D1")
        text((X(BOOST[0]) + X(BOOST[2])) / 2, Y(BOOST[3]) + 13,
             "backlight boost", size=11, anchor="middle", color=SILK)

        for y, label in ((R3_Y, "R3"), (R4_Y, "R4")):
            add(f'<rect x="{X(13.2):.1f}" y="{Y(y) - 6:.1f}" width="{MM * 2.2:.1f}" '
                f'height="12" fill="none" stroke="{SILK}" stroke-width="1.4"/>')
            text(X(16.0), Y(y), f"{label}, 0 \u03a9", size=11, color=SILK)

        text(X(13.0), Y(37.6), "PMOD-RGBLCD v1.3", size=16, color=SILK,
             family=MONO)
    else:
        box(*FPC, "", dashed=True)
        text((X(FPC[0]) + X(FPC[2])) / 2, Y(FPC[3]) + 14,
             "ribbon connector, other side", size=11, anchor="middle",
             color="#9a9a9a")

    # Header outline and pads

    xa, xb = sorted((X(COL_OUTER - 1.3), X(COL_INNER + 1.3)))
    add(f'<rect x="{xa:.1f}" y="{Y(ROW1 - 1.3):.1f}" width="{xb - xa:.1f}" '
        f'height="{MM * (14 * PITCH + 2.6):.1f}" fill="none" stroke="{SILK}" '
        f'stroke-width="1.6"/>')

    for n, name in J2.items():
        x = X(COL_OUTER if n <= 15 else COL_INNER)
        y = Y(ROW1 + PITCH * (row_of(n) - 1))
        ring = color_of(name)
        fill = PIN1 if n == 1 else COPPER

        if ring:
            add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{MM * 1.15:.1f}" '
                f'fill="none" stroke="{ring}" stroke-width="3"/>')

        s = MM * 0.85
        if n == 1:
            add(f'<rect x="{x - s:.1f}" y="{y - s:.1f}" width="{2 * s:.1f}" '
                f'height="{2 * s:.1f}" fill="{fill}" stroke="#fff" stroke-width="1.5"/>')
        else:
            add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{s:.1f}" fill="{fill}" '
                f'stroke="#6b5520" stroke-width="1"/>')

    # Labels: outer column outside the board, inner column inside

    for n, name in J2.items():
        y = Y(ROW1 + PITCH * (row_of(n) - 1))
        color = color_of(name) or INK

        if n <= 15:
            label = f"{n:>2} {name}" if mirrored else f"{name} {n:>2}"
            x = (ox + w + 14) if mirrored else (ox - 14)
            text(x, y, label, size=12, anchor="start" if mirrored else "end",
                 family=MONO, color=color, weight="bold" if n == 1 else "normal")
        else:
            label = f"{name} {n}" if mirrored else f"{n} {name}"
            x = X(COL_INNER + 1.9)
            text(x, y, label, size=11, anchor="end" if mirrored else "start",
                 family=MONO, color={V5: "#ff6b7a"}.get(color_of(name), color_of(name)) or SILK)

    return X, Y


def arrow_to(x0, y0, x1, y1):
    add(f'<line x1="{x0:.1f}" y1="{y0:.1f}" x2="{x1:.1f}" y2="{y1:.1f}" '
        f'stroke="{PIN1}" stroke-width="4" marker-end="url(#head)"/>')


# ---------------------------------------------------------------------------

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
    f'viewBox="0 0 {W} {H}">')
add('<title>PMOD-RGBLCD v1.3: where pin 1 of header J2 is</title>')
add(f'<defs><marker id="head" viewBox="0 0 10 10" refX="8" refY="5" '
    f'markerWidth="5" markerHeight="5" orient="auto-start-reverse">'
    f'<path d="M 0 0 L 10 5 L 0 10 z" fill="{PIN1}"/></marker></defs>')
add(f'<rect width="{W}" height="{H}" fill="#ffffff"/>')

text(40, 36, "PMOD-RGBLCD v1.3: where pin 1 of header J2 is", size=24,
     weight="bold")
text(40, 68, "Pin 1 is the square pad in the corner of the header at the board "
     "edge, at the end next to the backlight boost and away from the "
     "\"PMOD-RGBLCD v1.3\" text.", size=15, color=MUTED)
text(40, 92, "The outer column, next to the board edge, is pins 1 to 15. The "
     "inner column is pins 30 to 16, so pin 30 is beside pin 1.",
     size=15, color=MUTED)

TOP_X, TOP_Y = 250, 230
BOT_X, BOT_Y = 790, 230

X1, Y1 = board(TOP_X, TOP_Y, False, "Component side",
               "the side with the ribbon connector and the text")
X2, Y2 = board(BOT_X, BOT_Y, True, "Solder side",
               "the board turned over left to right")

# Pin 1 callouts

px, py = X1(COL_OUTER), Y1(ROW1)
arrow_to(px - 150, py - 60, px - 14, py - 10)
text(px - 156, py - 72, "PIN 1", size=20, anchor="end", weight="bold",
     color=PIN1)
text(px - 156, py - 50, "square pad", size=13, anchor="end", color=PIN1)

px, py = X2(COL_OUTER), Y2(ROW1)
arrow_to(px + 150, py - 60, px + 14, py - 10)
text(px + 156, py - 72, "PIN 1", size=20, anchor="start", weight="bold",
     color=PIN1)
text(px + 156, py - 50, "square pad", size=13, anchor="start", color=PIN1)

# Legend

ly = TOP_Y + MM * BOARD_H + 46
lx = 40

for color, label in ((PIN1, "pin 1"), (GND, "GND"), (V33, "3.3 V"), (V5, "5 V, backlight only")):
    if label == "pin 1":
        add(f'<rect x="{lx + 2}" y="{ly - 7}" width="14" height="14" fill="{PIN1}"/>')
    else:
        add(f'<circle cx="{lx + 9}" cy="{ly}" r="8" fill="none" stroke="{color}" '
            f'stroke-width="3"/>')
    text(lx + 24, ly, label, size=14)
    lx += 60 + 9 * len(label)

# Check with a multimeter

cy = ly + 40
add(f'<rect x="40" y="{cy}" width="{W - 80}" height="{H - cy - 30}" rx="10" '
    f'fill="#f4f6f9" stroke="#c9ced8" stroke-width="1.5"/>')
text(60, cy + 26, "Check the orientation before wiring, with a multimeter in "
     "continuity mode and nothing powered:", size=15, weight="bold")

checks = [
    "1.  Count rows from the end you believe is pin 1. Rows 5 and 14 are GND "
    "in both columns: all four pins beep with each other.",
    "2.  If instead rows 2 and 11 beep with each other, the board is turned "
    "end for end and pin 1 is at the other end.",
    "3.  Row 8 tells the columns apart: the outer pin, 8, beeps with GND through "
    "the 0 \u03a9 R3; the inner pin, 23, does not. Pin 23 is the 5 V input, through R4.",
]

for i, line in enumerate(checks):
    text(60, cy + 60 + 28 * i, line, size=14)

add("</svg>")
OUT.write_text("\n".join(svg) + "\n")
print(f"Wrote {OUT}")
