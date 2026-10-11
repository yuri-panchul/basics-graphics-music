"""Regenerate the two wiring SVGs from wiring.csv; standard library only.

Rasterize with: inkscape wiring.svg --export-filename=wiring.png
               inkscape wiring_audio.svg --export-filename=wiring_audio.png
"""

import csv
from html import escape
from pathlib import Path


HERE = Path(__file__).resolve().parent
ROWS = list(csv.DictReader((HERE / "wiring.csv").read_text().splitlines()))
INK = "#17324d"
RED, GREEN, BLUE, GOLD = "#bc3545", "#17844e", "#2469c4", "#a66c05"


class Diagram:
    def __init__(self, height, title, description):
        self.parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="{height}" '
                      f'viewBox="0 0 1600 {height}" role="img">',
                      f'<title>{escape(title)}</title><desc>{escape(description)}</desc>',
                      '<style>text{font-family:DejaVu Sans,sans-serif;fill:#17324d}'
                      '.mono{font-family:DejaVu Sans Mono,monospace}</style>',
                      f'<rect width="1600" height="{height}" fill="#f2f6fa"/>']
        self.text(40, 56, title, 30, bold=True)
        self.text(40, 91, description, 17)

    def text(self, x, y, value, size=18, bold=False, color=INK, anchor="start", mono=False):
        self.parts.append(f'<text x="{x}" y="{y}" font-size="{size}" '
                          f'font-weight="{700 if bold else 400}" text-anchor="{anchor}" '
                          f'class="{"mono" if mono else ""}" style="fill:{color}">{escape(str(value))}</text>')

    def rect(self, x, y, w, h, fill="white", stroke="#ccdae6"):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" '
                          f'fill="{fill}" stroke="{stroke}"/>')

    def line(self, x1, y1, x2, y2, color=INK, width=3):
        self.parts.append(f'<path d="M{x1} {y1} L{x2} {y2}" fill="none" stroke="{color}" stroke-width="{width}"/>')

    def dot(self, x, y, color=INK):
        self.parts.append(f'<circle cx="{x}" cy="{y}" r="5" fill="{color}"/>')

    def wire(self, y, row, right=None, color=INK):
        self.text(60, y + 6, f'{row["header"]:6}  GPIO {int(row["gpio"]):2}  FPGA {row["fpga_pin"]:2}', 17, mono=True)
        self.line(410, y, 560, y, color)
        self.dot(410, y, color)
        self.dot(560, y, color)
        self.text(585, y + 6, right or f'{row["destination"]:5}  {row["label"]}', 18, bold=True, color=color)

    def save(self, name):
        (HERE / name).write_text("\n".join(self.parts + ["</svg>"]) + "\n")


def main_diagram():
    d = Diagram(1500, "BRS-100 · RGB LCD + TM1638 jumper connections",
                "480 × 272 RGB565 • wuxx PMOD-RGBLCD v1.3 • Proposed wiring; match your hardware revision before powering it.")
    d.rect(35, 115, 885, 810)
    d.text(60, 151, "LCD signal jumpers · one line = one wire", 22, bold=True)
    d.text(60, 183, "BRS-100 header / GPIO / FPGA pin", 17)
    d.text(585, 183, "Adapter J2 / signal", 17)
    d.text(60, 211, "Rows below are grouped by signal, not physical socket order.", 16)
    for i, row in enumerate(ROWS[:20]):
        color = RED if row["signal"].startswith("LCD_R") else GREEN if row["signal"].startswith("LCD_G") else BLUE if row["signal"].startswith("LCD_B") else GOLD
        d.wire(247 + i * 31, row, color=color)
    d.text(60, 894, "RGB bits 0 → 4/5 run from least to most significant.", 17)

    d.rect(950, 115, 615, 530)
    d.text(975, 151, "BRS-100 · component side · USB-C at top", 21, bold=True)
    d.text(1010, 185, "J5 (left)", 18, bold=True)
    d.text(1305, 185, "J6 (right)", 18, bold=True)
    d.rect(1200, 195, 90, 40, "#e7edf4")
    d.text(1245, 221, "USB-C", 16, anchor="middle")
    for j in range(18):
        y = 217 + j * 23
        for col, header in [(0, 5), (1, 6)]:
            x = 980 + col * 325
            gpio = j + 1 + col * 16
            label = f'{j+1:2}  GPIO {gpio:2}' if j < 16 else '17  GND' if j == 16 else '18  +5 V' if col == 0 else '18  +3.3 V'
            color = INK if j < 17 else RED if col == 0 else GOLD
            d.dot(x, y - 5, color)
            d.text(x + 15, y, label, 17, color=color, mono=True)
    d.text(975, 632, "J6.1 = GPIO 17. J6.17 is GND, not GPIO 17.", 16, bold=True)

    d.rect(950, 665, 615, 530)
    d.text(975, 701, "Adapter J2 · v1.3 PCB component-side view", 20, bold=True)
    d.text(975, 730, "Follow the PCB pin-1 mark; do not count odd/even.", 16)
    names = {1:'G0',2:'G1',3:'G2',4:'G3',5:'GND',6:'3V3',7:'G4',8:'GND*',9:'G5',10:'CLK',11:'HS',12:'VS',13:'DE',14:'GND',15:'3V3',16:'3V3',17:'GND',18:'B4',19:'B3',20:'B2',21:'B1',22:'B0',23:'+5V*',24:'R4',25:'3V3',26:'GND',27:'R3',28:'R2',29:'R1',30:'R0'}
    for j in range(15):
        y = 764 + j * 25
        for x, pin in [(1010, j + 1), (1325, 30 - j)]:
            label = names[pin]
            color = RED if label.startswith('R') or label.startswith('+5') else GREEN if label.startswith('G') and label != 'GND' and label != 'GND*' else BLUE if label.startswith('B') else INK
            d.dot(x, y - 5, color)
            d.text(x + 15, y, f'{pin:2}  {label}', 17, mono=True, color=color)
    d.text(975, 1175, "* J2.8 via R3; J2.23 via R4. Both are 0 Ω links.", 16)

    d.rect(35, 945, 885, 250)
    d.text(60, 982, "TM1638 · use a 3.3 V ↔ 5 V translator", 22, bold=True)
    d.text(60, 1013, "Example: TXS0104E module; A = 3.3 V, B = 5 V.", 17)
    for i, row in enumerate(ROWS[20:23]):
        d.wire(1052 + i * 35, row, f'A{i+1} ↔ B{i+1} → TM {row["label"]}', color="#7541a0")
    d.text(60, 1163, "DIO is bidirectional. Do not connect a 5 V module directly to GPIO.", 17, bold=True)

    d.rect(35, 1215, 1530, 245, "#fff9e9", "#e7d3a0")
    d.text(60, 1255, "Power and assembly", 24, bold=True)
    notes = [
        "J5.18 (+5 V) → adapter J2.23, TM1638 VCC, translator VCCB. Leave the adapter USB-C unplugged.",
        "J6.18 (+3.3 V) → adapter J2.6, translator VCCA and OE. Use a power distribution strip for fan-out.",
        "J5.17 / J6.17 (GND) → adapter J2.5 + J2.14 + J2.17 + J2.26, translator GND and TM1638 GND.",
        "Open adapter SB1–SB4 for independent RGB565. Seat the compatible 40-pin panel in J1 with power removed.",
        "Keep signal jumpers short. Optional microphone / DAC / three spare GPIOs: see wiring_audio.svg and README.md."]
    for i, note in enumerate(notes):
        d.text(60, 1295 + i * 31, note, 18)
    d.text(40, 1484, "Configuration: brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_codex · Signal source: wiring.csv · References and limitations: README.md", 15)
    d.save("wiring.svg")


def audio_diagram():
    d = Diagram(1600, "BRS-100 · optional microphone and sound DAC",
                "These connections fit alongside the LCD and TM1638. Use the same ground and power distribution strip.")
    d.rect(35, 120, 1530, 365)
    d.text(60, 160, "INMP441 I²S microphone · 3.3 V", 25, bold=True)
    for i, row in enumerate(ROWS[23:26]):
        d.wire(215 + i * 42, row, f'INMP441 {row["destination"]}', GREEN)
    d.text(60, 376, "J6.18 (+3.3 V) → INMP441 VDD/VCC", 20)
    d.text(60, 413, "GND strip → INMP441 GND and L/R (left channel)", 20)
    d.text(60, 454, "SD travels from the microphone to the FPGA. WS and SCK travel from FPGA to microphone.", 18)

    d.rect(35, 510, 1530, 460)
    d.text(60, 555, "PCM5102 / PCM5102A I²S DAC · 3.3 V logic", 25, bold=True)
    for i, row in enumerate(ROWS[26:29]):
        d.wire(610 + i * 42, row, f'PCM5102 {row["destination"]}', BLUE)
    lines = ["GND strip → DAC GND, SCK, FLT, DEMP and FMT. SCK is not BCK: tie SCK low to use the internal PLL.",
             "J6.18 (+3.3 V) → XSMT (unmute), unless your module already straps it high.",
             "Only a module with a documented 5 V VIN and onboard regulator: J5.18 (+5 V) → VIN.",
             "For a 3.3 V-only module, use J6.18 (+3.3 V). Never infer the voltage from a generic VCC label.",
             "DAC L/R analog outputs → powered speakers or amplifier. They are line-level outputs."]
    for i, line in enumerate(lines):
        d.text(60, 778 + i * 35, line, 18)

    d.rect(35, 995, 1530, 215)
    d.text(60, 1036, "Still available to the lab", 24, bold=True)
    for i, row in enumerate(ROWS[29:]):
        d.wire(1080 + i * 40, row, row["signal"] + " · 3.3 V user I/O", GOLD)

    d.rect(35, 1235, 1530, 320, "#fff9e9", "#e7d3a0")
    d.text(60, 1280, "Connection order and checks", 24, bold=True)
    lines = ["1. Remove board power before adding jumpers. Find J6 by the main wiring.svg component-side drawing.",
             "2. Connect common ground and the module's documented supply. Check L/R, SCK and the DAC format straps.",
             "3. Add the six I²S signal wires shown above. No GPIO is shared with the LCD or TM1638.",
             "4. Reconnect board USB-C. Start with color stripes, then a microphone or music lab.",
             "5. Verify I²S clocks and signal levels on the assembled hardware. Jumper wiring has not been bench-tested.",
             "An absent microphone reads zero through the FPGA input pulldown. Audio modules are optional."]
    for i, line in enumerate(lines):
        d.text(60, 1325 + i * 35, line, 19)
    d.text(40, 1585, "Configuration: brisbane_brs_100_tm1638_pmod_rgblcd_480_272_by_codex · See README.md for sources, setup and validation scope.", 16)
    d.save("wiring_audio.svg")


if __name__ == "__main__":
    main_diagram()
    audio_diagram()
