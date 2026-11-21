#!/usr/bin/env python3
"""Draw the wiring of the microphone and the DAC to header P4 of the board.

Usage:  python3 generate_wiring_diagram.py

Writes wiring_weact.svg, wiring_gy_pcm5102.svg and their Russian versions
wiring_weact_ru.svg and wiring_gy_pcm5102_ru.svg next to this script.
Render them to PNG with:

    for f in wiring_*.svg; do inkscape "$f" --export-type=png --export-dpi=96; done

The pins and signals must match board_specific_top.sv and board_specific.qsf.
"""

from pathlib import Path

HERE = Path(__file__).resolve().parent

W, H = 1040, 700
PITCH = 40

# The board's top edge with JP2 and the 2 x 11 header P4, as in the seller's photo

BOARD_TOP = 70
ROW_OUTER = 120    # The row nearer the board edge
ROW_INNER = 160
JP2_X0 = 70        # x of the first JP2 column
P4_X0 = 250        # x of the first, unlabeled, P4 column

COLORS = {
    "BCK": "#d9480f", "DIN": "#c99400", "LRCK": "#7048e8",
    "SCK": "#1971c2", "SD": "#2b8a3e", "WS": "#0c8599",
    "VDD": "#e03131", "GND": "#212529", "LR": "#868e96",
    "VIN": "#e03131",
}

# The 8 labeled columns of P4, left to right: (FPGA pins, signal)

P4_COLUMNS = [
    ((142, 141), "BCK"),
    ((138, 137), "DIN"),
    ((136, 135), "LRCK"),
    ((133, 132), "SD"),
    ((129, 128), "VDD"),
    ((127, 126), "GND"),
    ((125, 124), "WS"),
    ((121, 120), "SCK"),
]

TEXT = {
    "en": {
        "title_weact": "Microphone INMP441 and DAC WeAct PCM5100A on header P4",
        "title_gy": "Microphone INMP441 and DAC GY-PCM5102 on header P4",
        "edge": "edge of the board",
        "jp2": "JP2",
        "jp2_note": "JP2: power for the DAC, measure it first (step 3)",
        "p4": "P4",
        "unknown": "not used",
        "either": ["Each wire may go to either pin", "of its column: both pins carry", "the same signal."],
        "supply": "3.3–5 V",
        "gnd": "GND",
        "mic": "INMP441, chip side up",
        "weact": "WeAct I2S Earphone Module (PCM5100A)",
        "gy": "GY-PCM5102 (PCM5102A): line out",
        "nc": "free",
        "mic_power": "VDD and GND come from FPGA pins",
        "signals": {
            "BCK": "BCK", "DIN": "DIN", "LRCK": "LRCK", "SCK": "SCK", "SD": "SD",
            "WS": "WS", "VDD": "3.3 V", "GND": "GND",
        },
    },
    "ru": {
        "title_weact": "Микрофон INMP441 и ЦАП WeAct PCM5100A на разъёме P4",
        "title_gy": "Микрофон INMP441 и ЦАП GY-PCM5102 на разъёме P4",
        "edge": "край платы",
        "jp2": "JP2",
        "jp2_note": "JP2: питание ЦАП, сначала измерьте (шаг 3)",
        "p4": "P4",
        "unknown": "не используются",
        "either": ["Каждый провод можно подключить", "к любому из двух штырей своего", "столбца: на них один сигнал."],
        "supply": "3,3–5 В",
        "gnd": "GND",
        "mic": "INMP441, микросхемой вверх",
        "weact": "WeAct I2S Earphone Module (PCM5100A)",
        "gy": "GY-PCM5102 (PCM5102A): линейный выход",
        "nc": "свободен",
        "mic_power": "VDD и GND — от выводов ПЛИС",
        "signals": {
            "BCK": "BCK", "DIN": "DIN", "LRCK": "LRCK", "SCK": "SCK", "SD": "SD",
            "WS": "WS", "VDD": "3,3 В", "GND": "GND",
        },
    },
}


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def text(x, y, s, size=14, anchor="middle", weight="normal", color="#212529"):
    return (f'<text x="{x}" y="{y}" font-size="{size}" text-anchor="{anchor}" '
            f'font-weight="{weight}" fill="{color}">{esc(s)}</text>')


def pin(x, y, color="#adb5bd", r=7):
    return (f'<rect x="{x - r}" y="{y - r}" width="{2 * r}" height="{2 * r}" '
            f'fill="#f1f3f5" stroke="#495057" stroke-width="1.5"/>'
            f'<circle cx="{x}" cy="{y}" r="{r - 3}" fill="{color}"/>')


def wire(points, color, width=4):
    d = " ".join(f"{x},{y}" for x, y in points)
    return (f'<polyline points="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
            f'stroke-linejoin="round" stroke-linecap="round" opacity="0.9"/>')


def p4_x(column):
    """x of a P4 column: 0..2 are the unlabeled ones, 3..10 the labeled ones."""
    return P4_X0 + column * PITCH


def jp2_x(column):
    return JP2_X0 + column * PITCH


def draw(dac, lang):
    t = TEXT[lang]
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}" font-family="DejaVu Sans, Arial, sans-serif">',
           f'<rect width="{W}" height="{H}" fill="#ffffff"/>']

    title = t["title_weact"] if dac == "weact" else t["title_gy"]
    out.append(text(W / 2, 32, title, 20, weight="bold"))

    # The board

    out.append(f'<rect x="30" y="{BOARD_TOP}" width="{W - 60}" height="210" rx="10" '
               f'fill="#dbe4ff" stroke="#364fc7" stroke-width="2"/>')
    out.append(text(W - 50, BOARD_TOP + 20, t["edge"], 12, anchor="end", color="#364fc7"))

    # JP2: 2 x 3

    out.append(f'<rect x="{jp2_x(0) - 18}" y="{ROW_OUTER - 18}" width="{2 * PITCH + 36}" '
               f'height="{ROW_INNER - ROW_OUTER + 36}" fill="none" stroke="#495057" '
               f'stroke-dasharray="4 3"/>')
    out.append(text(45, BOARD_TOP - 12, t["jp2_note"], 13, anchor="start", weight="bold",
                    color="#495057"))

    for c in range(3):
        for y in (ROW_OUTER, ROW_INNER):
            out.append(pin(jp2_x(c), y))


    # P4: 2 x 11, the first 3 columns without labels

    x0, x1 = p4_x(0) - 18, p4_x(10) + 18
    out.append(f'<rect x="{x0}" y="{ROW_OUTER - 18}" width="{x1 - x0}" '
               f'height="{ROW_INNER - ROW_OUTER + 36}" fill="none" stroke="#495057"/>')
    out.append(text(x0 - 8, ROW_OUTER + 25, t["p4"], 16, anchor="end", weight="bold"))
    out.append(text(p4_x(1), ROW_INNER + 34, t["unknown"], 11, color="#868e96"))

    for c in range(3):
        for y in (ROW_OUTER, ROW_INNER):
            out.append(pin(p4_x(c), y))

    for i, ((a, b), sig) in enumerate(P4_COLUMNS):
        x = p4_x(3 + i)
        color = COLORS[sig]

        for y in (ROW_OUTER, ROW_INNER):
            out.append(pin(x, y, color))

        out.append(text(x, ROW_OUTER - 26, t["signals"][sig], 11, weight="bold", color=color))

        if sig == "GND":
            out.append(text(x, ROW_OUTER - 40, "L/R", 11, weight="bold", color=COLORS["LR"]))
        out.append(text(x, ROW_INNER + 30, f"P{a}", 11))
        out.append(text(x, ROW_INNER + 44, f"P{b}", 11))

    for i, line in enumerate(t["either"]):
        out.append(text(700, ROW_OUTER + 20 + i * 20, line, 13, anchor="start", color="#364fc7"))

    # The DAC module, lower left

    if dac == "weact":
        dac_pins = ["VCC", "GND", "/SD", "MC", "BCK", "DIN", "WS"]
        dac_title = t["weact"]
    else:
        dac_pins = ["SCK", "BCK", "DIN", "LCK", "GND", "VIN"]
        dac_title = t["gy"]

    dac_y = 560
    dac_x0 = 90
    width = (len(dac_pins) - 1) * PITCH + 60
    out.append(f'<rect x="{dac_x0 - 30}" y="{dac_y - 22}" width="{width}" height="100" rx="6" '
               f'fill="#f8f0fc" stroke="#862e9c" stroke-width="2"/>')
    out.append(text(dac_x0 - 30 + width / 2, dac_y + 68, dac_title, 13, weight="bold",
                    color="#862e9c"))

    dac_xy = {}

    for i, name in enumerate(dac_pins):
        x = dac_x0 + i * PITCH
        dac_xy[name] = (x, dac_y)
        out.append(pin(x, dac_y))
        out.append(text(x, dac_y + 30, name, 12))

    # DAC wires: signals to P4, power to JP2. JP2 column 1 is drawn as the
    # supply and column 2 as GND, as its silkscreen "...V GND" suggests.

    supply = (jp2_x(1), ROW_INNER)
    gnd_a = (jp2_x(2), ROW_INNER)
    gnd_b = (jp2_x(2), ROW_OUTER)

    out.append(text(supply[0] - 8, supply[1] + 30, t["supply"], 11, anchor="end",
                    weight="bold", color=COLORS["VDD"]))
    out.append(text(gnd_a[0] + 24, gnd_a[1] + 30, t["gnd"], 11, anchor="start",
                    weight="bold", color=COLORS["GND"]))

    def route(src, dst, lane, color):
        return wire([src, (src[0], lane), (dst[0], lane), dst], color)

    signal_of = {"BCK": "BCK", "DIN": "DIN", "WS": "LRCK", "LCK": "LRCK"}
    column_x = {sig: p4_x(3 + i) for i, (_, sig) in enumerate(P4_COLUMNS)}
    lanes = iter(range(330, 520, 22))

    for name in dac_pins:
        if name in signal_of:
            sig = signal_of[name]
            out.append(route(dac_xy[name], (column_x[sig], ROW_INNER), next(lanes),
                             COLORS[sig]))
        elif name in ("VCC", "VIN"):
            out.append(route(dac_xy[name], supply, next(lanes), COLORS["VDD"]))
        elif name == "GND":
            out.append(route(dac_xy[name], gnd_a, next(lanes), COLORS["GND"]))
        elif name == "SCK":
            # To the outer GND pin of JP2, past the inner one
            x, y = dac_xy[name]
            lane, tx = next(lanes), gnd_b[0] + 16
            out.append(wire([(x, y), (x, lane), (tx, lane), (tx, gnd_b[1]), gnd_b],
                            COLORS["GND"]))
        else:
            x, y = dac_xy[name]
            out.append(text(x, y + 46, t["nc"], 10, color="#868e96"))

    # The microphone, lower right: seen from the label side, the row
    # SCK, WS, L/R above the row SD, VDD, GND

    cx, cy = 820, 560
    out.append(f'<circle cx="{cx}" cy="{cy}" r="74" fill="#212529" stroke="#c99400" '
               f'stroke-width="5"/>')
    out.append(text(cx, cy + 102, t["mic"], 13, weight="bold"))
    out.append(text(cx, cy + 120, t["mic_power"], 11, color="#495057"))

    # Seen from the chip side, the rows read L/R, WS, SCK and GND, VDD, SD

    mic_top = ["L/R", "WS", "SCK"]
    mic_bottom = ["GND", "VDD", "SD"]
    mic_xy = {}

    for i, name in enumerate(mic_top):
        x, y = cx - PITCH + i * PITCH, cy - 34
        mic_xy[name] = (x, y)
        out.append(pin(x, y))
        out.append(text(x, y + 24, name, 11, color="#ffffff"))

    for i, name in enumerate(mic_bottom):
        x, y = cx - PITCH + i * PITCH, cy + 34
        mic_xy[name] = (x, y)
        out.append(pin(x, y))
        out.append(text(x, y - 14, name, 11, color="#ffffff"))

    # The upper row goes straight up. The lower row goes down, around the
    # left of the module and up. Lanes are chosen so that no wires cross.

    for name, lane in (("L/R", 380), ("WS", 356), ("SCK", 332)):
        x, y = mic_xy[name]

        if name == "L/R":
            tx = column_x["GND"] + 16
            points = [(x, y), (x, lane), (tx, lane), (tx, ROW_OUTER),
                      (column_x["GND"], ROW_OUTER)]
            color = COLORS["LR"]
        else:
            points = [(x, y), (x, lane), (column_x[name], lane), (column_x[name], ROW_INNER)]
            color = COLORS[name]

        out.append(wire(points, color, 3))

    for name, side, down, lane in (("GND", 684, 610, 404), ("VDD", 672, 622, 428),
                                   ("SD", 660, 634, 452)):
        x, y = mic_xy[name]
        points = [(x, y), (x, down), (side, down), (side, lane),
                  (column_x[name], lane), (column_x[name], ROW_INNER)]
        out.append(wire(points, COLORS[name], 3))

    out.append("</svg>")
    return "\n".join(out) + "\n"


def main():
    for dac in ("weact", "gy_pcm5102"):
        for lang, suffix in (("en", ""), ("ru", "_ru")):
            path = HERE / f"wiring_{dac}{suffix}.svg"
            path.write_text(draw("weact" if dac == "weact" else "gy", lang), encoding="utf-8")
            print(f"wrote {path.name}")


if __name__ == "__main__":
    main()
