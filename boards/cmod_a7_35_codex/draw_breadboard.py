#!/usr/bin/env python3
"""Draw the DAC breadboard assembly in EN/RU as editable, deterministic SVG.

Cmod: 0.6-inch row spacing, 0.1-inch pitch, Pmod above and USB below.
WeAct P1: manufacturer's V1.0 schematic and Images/1.png connector order.
Regulator terminals are functional labels, not a particular module footprint.
"""
from html import escape
from pathlib import Path

HERE = Path(__file__).resolve().parent
W, H = 1450, 1160
COL = dict(zip('abcdefghij', [176, 198, 220, 242, 264, 330, 352, 374, 396, 418]))
VU, V33, GND = '#cc343b', '#d47a08', '#263345'
BCK, DIN, WS = '#176ab7', '#07836d', '#8245b2'


def row(n):
    return 250 + (n - 1) * 22


for language in ('en', 'ru'):
    def tr(en, ru):
        return en if language == 'en' else ru

    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="title desc">',
           '<title id="title">' + tr('Cmod A7-35T: DAC breadboard wiring', 'Cmod A7-35T: ЦАП на макетной плате') + '</title>',
           '<desc id="desc">' + tr('Top view. Cmod pins 1 and 48 occupy c4 and g4; pins 24 VU and 25 ground occupy c27 and g27. USB power feeds the DAC VCC through VU. DAC ground and MCLK connect to the ground rail. DIP 32, 33, 34 connect to BCK, DIN, WS. A separate regulator supplies the 3.3 V accessory rail.', 'Вид сверху. Выводы Cmod 1 и 48 установлены в c4 и g4; выводы 24 VU и 25 GND — в c27 и g27. Питание ЦАП поступает от USB через VU. GND и MCLK ЦАП соединены с землёй. DIP 32, 33, 34 соединены с BCK, DIN, WS. Отдельный стабилизатор питает шину периферии 3,3 В.') + '</desc>',
           '<style>text{font-family:Arial,sans-serif;fill:#203343}.title{font-size:31px;font-weight:700}.h{font-size:23px;font-weight:700}.t{font-size:18px}.s{font-size:15px}.tiny{font-size:12px}.white{fill:#fff}.hole{fill:#7f858a;stroke:#e5e6e8;stroke-width:2}</style>',
           '<rect width="1450" height="1160" fill="#f3f6f7"/>']

    def rect(x, y, w, h, fill, stroke='none', radius=8):
        svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')

    def text(x, y, value, cls='t', anchor='start', color=None):
        style = f' style="fill:{color}"' if color else ''
        svg.append(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}"{style}>{escape(str(value))}</text>')

    def circle(x, y, radius=4, fill='#7f858a', stroke='#e5e6e8'):
        svg.append(f'<circle cx="{x}" cy="{y}" r="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')

    def line(points, color, width=3, halo=False):
        d = 'M' + ' L'.join(f'{x},{y}' for x, y in points)
        if halo:
            svg.append(f'<path d="{d}" fill="none" stroke="#fff" stroke-width="{width + 4}" stroke-linecap="round" stroke-linejoin="round"/>')
        svg.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')

    def wire(points, color):
        line(points, color, 5, True)
        for x, y in (points[0], points[-1]):
            circle(x, y, 5, color, '#fff')

    text(45, 48, tr('Cmod A7-35T → WeAct PCM5100A', 'Cmod A7-35T → WeAct PCM5100A'), 'title')
    text(45, 79, tr('DAC power + I²S wiring on a solderless breadboard · top view', 'Питание ЦАП и I²S на беспаечной макетной плате · вид сверху'))
    for x, color, label in [(48, VU, 'VU ≈ 5 V'), (265, GND, 'GND'), (430, V33, '3.3 V'), (620, BCK, 'BCK'), (780, DIN, 'DIN'), (940, WS, 'WS')]:
        line([(x, 112), (x + 32, 112)], color, 5)
        text(x + 44, 118, label)
    text(45, 147, tr('Solid dots are wire ends. Crossing wires do not connect.', 'Точки — концы проводов. Пересечения проводов не соединяются.'), 's')

    # A 30-row terminal strip. Each a-e / f-j group is electrically separate.
    rect(52, 202, 510, 745, '#e3e4e5', '#b2b9be', 16)
    rect(66, 218, 482, 712, '#f8f8f6', '#c7ccd0', 10)
    rect(284, 230, 26, 675, '#d8dadd', radius=2)
    for x, label, color in [(95, '−', GND), (123, 'VU', VU), (475, '3.3', V33), (503, '−', GND)]:
        line([(x, 242), (x, 898)], color, 2)
        text(x, 231, label, 's', 'middle', color)
        for n in range(1, 31):
            circle(x, row(n), 3.5)
    for col, x in COL.items():
        text(x, 232, col, 's', 'middle')
        for n in range(1, 31):
            circle(x, row(n), 3.5)
    for n in range(1, 31):
        text(153, row(n) + 4, n, 'tiny', 'middle')
        text(440, row(n) + 4, n, 'tiny', 'middle')
    for n, color in [(18, WS), (19, DIN), (20, BCK), (27, GND)]:
        line([(COL['f'], row(n)), (COL['j'], row(n))], color, 2)
    line([(COL['a'], row(27)), (COL['e'], row(27))], VU, 2)

    # Real Cmod header coordinates; the PCB component artwork is simplified.
    rect(209, 274, 154, 605, '#14638b', '#104661', 5)
    rect(214, 278, 144, 31, '#222a31', radius=2)
    text(286, 300, 'Pmod JA → Tiny VGA', 'tiny', 'middle', '#fff')
    for pin in range(1, 25):
        y = row(pin + 3)
        for x, number in [(COL['c'], pin), (COL['g'], 49 - pin)]:
            color = VU if number == 24 else GND if number == 25 else '#d8b56b'
            circle(x, y, 4.5, color, '#f5e2a7')
            text(x + (12 if x == COL['c'] else -12), y + 4, number, 'tiny', 'start' if x == COL['c'] else 'end', '#fff')
    circle(228, 309, 3, '#fff', '#fff')
    rect(249, 373, 73, 88, '#202b36', '#89949c', 2)
    text(285, 409, 'Artix-7', 'tiny', 'middle', '#fff')
    text(285, 430, '35T', 'tiny', 'middle', '#fff')
    text(285, 499, 'Cmod A7', 's', 'middle', '#fff')
    text(285, 520, '35T', 's', 'middle', '#fff')
    for y in (553, 590):
        rect(255, y, 62, 23, '#25323c', radius=1)
    rect(256, 835, 60, 49, '#a5b1ba', '#536471', 3)
    rect(264, 843, 44, 23, '#263345', radius=3)
    line([(286, 883), (286, 989)], '#6e7882', 21)
    text(286, 1016, 'Micro-USB', 's', 'middle')
    text(286, 1039, tr('to PC / USB power', 'к ПК / питание USB'), 's', 'middle')

    # DAC pads follow the actual WeAct V1 header order with the jack to the right.
    rect(887, 335, 390, 245, '#3b3c23', '#252b25', 6)
    rect(891, 343, 30, 226, '#202822', radius=2)
    text(1045, 368, 'WeAct V1', 'h', color='#fff')
    text(1045, 396, 'PCM5100A', 't', color='#fff')
    rect(1088, 432, 82, 96, '#1b2025', '#818774', 2)
    rect(1238, 370, 86, 63, '#303740', '#859094', 3)
    text(1280, 406, '3.5 mm', 'tiny', 'middle', '#fff')
    text(1113, 554, tr('Headphones', 'Наушники'), 't', 'middle', '#fff')
    for index, label in enumerate(['VCC', 'GND', '/SD', 'MCLK', 'BCK', 'DIN', 'WS']):
        y = 360 + index * 28
        circle(900, y, 5, '#dec68c', '#f0dfb1')
        text(930, y + 5, f'{index + 1}  {label}', 's', color='#fff')
    text(790, 421, tr('open', 'свободен'), 's')
    line([(868, 416), (886, 416)], '#88939c', 2)

    # Separate regulator module: only functional terminals are prescribed.
    rect(900, 815, 300, 160, '#25655a', '#17483f', 7)
    text(1050, 847, tr('3.3 V REGULATOR', 'СТАБИЛИЗАТОР 3,3 В'), 't', 'middle', '#fff')
    rect(1013, 871, 65, 49, '#24343a', '#9bb5a9', 2)
    text(921, 884, 'IN', 's', color='#fff')
    text(1178, 884, 'OUT', 's', 'end', '#fff')
    text(1160, 958, 'GND', 's', 'middle', '#fff')
    circle(900, 860, 5, '#dec68c')
    circle(1200, 860, 5, '#dec68c')
    circle(1160, 975, 5, '#dec68c')

    # Power: the rails and Cmod row links establish shared nets, not GPIO power.
    wire([(COL['b'], row(27)), (123, row(27))], VU)
    wire([(COL['j'], row(27)), (503, row(27))], GND)
    wire([(95, row(29)), (95, 921), (503, 921), (503, row(29))], GND)
    wire([(123, row(1)), (123, 180), (820, 180), (820, 360), (900, 360)], VU)
    wire([(503, row(6)), (740, row(6)), (740, 388), (900, 388)], GND)
    wire([(503, row(7)), (715, row(7)), (715, 444), (900, 444)], GND)
    wire([(COL['j'], row(20)), (600, row(20)), (600, 472), (900, 472)], BCK)
    wire([(COL['j'], row(19)), (625, row(19)), (625, 500), (900, 500)], DIN)
    wire([(COL['j'], row(18)), (650, row(18)), (650, 528), (900, 528)], WS)
    wire([(123, row(30)), (123, 1060), (800, 1060), (800, 860), (900, 860)], VU)
    wire([(503, row(30)), (503, 1090), (1380, 1090), (1380, 975), (1160, 975)], GND)
    wire([(1200, 860), (1340, 860), (1340, row(23)), (475, row(23))], V33)

    # Labels go above wires; labels do not imply additional connections.
    text(565, 169, tr('USB-derived VU → DAC VCC', 'VU от USB → VCC ЦАП'), 't', 'middle', VU)
    text(847, 274, tr('Supply ≈ 5 V', 'Питание ≈ 5 В'), 't', color=VU)
    text(667, 575, tr('32 → BCK   33 → DIN   34 → WS', '32 → BCK   33 → DIN   34 → WS'), 's')
    text(632, 600, tr('I²S signals: 3.3 V logic', 'Сигналы I²S: логика 3,3 В'), 's')
    rect(695, 620, 650, 85, '#fff8ea', '#e8c68f')
    text(715, 648, tr('3.3 V rail → TM1638 VCC + INMP441 VDD', 'Шина 3,3 В → VCC TM1638 + VDD INMP441'), 't')
    text(715, 675, tr('Their signal wires are in the full connection map.', 'Их сигнальные провода — на общей карте соединений.'), 's')
    text(894, 787, tr('Separate 3.3 V supply for display + microphone', 'Отдельное питание 3,3 В для индикатора и микрофона'), 's')
    text(850, 1004, tr('Use IN / OUT / GND labels on your regulator.', 'Ориентируйтесь на IN / OUT / GND стабилизатора.'), 's')
    text(850, 1028, tr('Its physical pin order may differ.', 'Физический порядок его выводов может отличаться.'), 's')
    text(847, 236, tr('Cmod: c4…c27 + g4…g27', 'Cmod: c4…c27 + g4…g27'), 's')
    text(50, 1127, tr('a–e connect within each row; f–j connect separately. Rails are drawn continuous: bridge any breaks on your board.', 'В строке соединены a–e и отдельно f–j. Шины нарисованы непрерывными: соедините перемычками их разрывы на своей плате.'), 's')
    text(50, 1151, tr('WeAct shown. For GY-PCM5102, use the guide’s signal-label table; header order varies. Disconnect power before rewiring.', 'Показан WeAct. Для GY-PCM5102 используйте таблицу сигналов: разъёмы различаются. Переставляйте провода при отключённом питании.'), 's')
    svg.append('</svg>')
    output = HERE / f'breadboard_dac_{language}.svg'
    output.write_text('\n'.join(svg) + '\n')
    print(output)
