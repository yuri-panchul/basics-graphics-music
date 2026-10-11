"""BRS-100 pin-map and RTL checks; no FPGA or EDA license needed.

Run from anywhere: python3 scripts/tests/test_brs100.py
Requires Icarus Verilog. Temporary simulation files stay outside the repository.
"""

import csv
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
BOARDS = sorted((REPO / "boards").glob("brisbane_brs_100_tm1638_pmod_rgblcd_*_by_codex_alt"))
BOARD = BOARDS[0]


def run(*args):
    result = subprocess.run([str(a) for a in args], text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(result.stdout + result.stderr)
    return result.stdout


class Brs100Test(unittest.TestCase):
    def test_programmer_mappings(self):
        # Exercise the actual dispatch functions with executable/function mocks;
        # no USB access, udev changes, process termination or programming occurs.
        with tempfile.TemporaryDirectory(prefix="brs100-programmer-") as tmp:
            tmp = Path(tmp)
            programmer = tmp / "programmer"
            programmer.write_text('#!/bin/bash\nprintf "ARG=%s\\n" "$@"\n')
            programmer.chmod(0o755)
            harness = tmp / "00_setup.source_bash"
            harness.write_text(f'''source {shlex.quote(str(REPO / "scripts/steps/00_setup_gowin.source_bash"))}
OSTYPE=msys
is_command_available_or_error () {{ :; }}
error () {{ printf '%s\\n' "$*" >&2; exit 1; }}
adj_path_for_gowin_win () {{ printf '%s' "$1"; }}
openFPGALoader () {{ printf 'ARG=%s\\n' "$@"; }}
gowin_prog_full_real_path={shlex.quote(str(programmer))}
fpga_board="$1"
"$2"
''')
            for board in BOARDS:
                output = run("bash", harness, board.name, "configure_fpga_gowin_openfpga")
                self.assertIn("ARG=-b\nARG=brs-100-gw1nr9", output)
                self.assertIn("ARG=impl/pnr/fpga_project.fs", output)
                output = run("bash", harness, board.name, "configure_fpga_gowin_proprietary")
                self.assertIn("ARG=-d\nARG=GW1NR-9C\nARG=-r\nARG=2", output)

    def test_pin_map(self):
        for board in BOARDS:
            with self.subTest(board=board.name):
                self.check_pin_map(board)

    def check_pin_map(self, BOARD):
        rows = list(csv.DictReader((BOARD / "wiring.csv").read_text().splitlines()))
        # Manufacturer header pinout, independent of our generated constraints.
        expected_pins = [25, 26, 27, 28, 29, 30, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
                         77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 57, 56, 55, 54, 53, 51]
        self.assertEqual(len(rows), 32)
        cst = (BOARD / "board_specific.cst").read_text()
        locations = re.findall(r'IO_LOC\s+"([^"]+)"\s+(\d+);', cst)
        self.assertEqual(len(locations), len(set(pin for _, pin in locations)))
        locations = dict(locations)
        self.assertEqual(len(locations), 44)  # 32 header + CLK + 2 KEY + 6 LED + UART + CS
        for n, (row, pin) in enumerate(zip(rows, expected_pins), 1):
            self.assertEqual(int(row["gpio"]), n)
            self.assertEqual(int(row["fpga_pin"]), pin)
            self.assertEqual(row["header"], f'J{5 if n <= 16 else 6}.{n if n <= 16 else n - 16}')
            self.assertEqual(locations[row["signal"]], str(pin))
        adapter = [row["destination"] for row in rows if row["peripheral"] == "LCD"]
        self.assertEqual(len(set(adapter)), 20)
        self.assertEqual(set(adapter), {f"J2.{i}" for i in
                         [1, 2, 3, 4, 7, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 24, 27, 28, 29, 30]})
        for port in [f"KEY[{i}]" for i in range(2)] + [f"LED[{i}]" for i in range(6)]:
            self.assertRegex(cst, rf'IO_PORT "{re.escape(port)}" IO_TYPE=LVCMOS18')

    def test_lcd_frames(self):
        with tempfile.TemporaryDirectory(prefix="brs100-lcd-") as tmp:
            exe = Path(tmp) / "lcd.vvp"
            for board in BOARDS:
                for latency in range(2 if "800_480" in board.name else 4):
                    with self.subTest(board=board.name, rgb_latency=latency):
                        run("iverilog", "-g2012", "-s", "tb", f"-Ptb.LATENCY={latency}",
                            "-I", board, "-o", exe, board / "brs100_lcd.sv", board / "tests/lcd/tb.sv")
                        self.assertIn("PASS LCD", run("vvp", exe))

    def test_wrapper(self):
        for board in BOARDS:
            with self.subTest(board=board.name):
                self.check_wrapper(board)

    def check_wrapper(self, BOARD):
        macros = ["INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE",
                  "INSTANTIATE_GRAPHICS_INTERFACE_MODULE",
                  "INSTANTIATE_MICROPHONE_INTERFACE_MODULE",
                  "INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE"]
        cases = [macros, [], macros + ["FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE"]]
        cases += [[macro] for macro in macros]
        peripheral = REPO / "peripherals"
        with tempfile.TemporaryDirectory(prefix="brs100-wrapper-") as tmp:
            tmp = Path(tmp)
            for case in cases:
                with self.subTest(macros=case):
                    # Put the include beside the test top to avoid dependence
                    # on lab-specific feature switches in the checkout.
                    (tmp / "lab_specific_board_config.svh").write_text(
                        "\n".join("`define " + macro for macro in case) + "\n")
                    (tmp / "tb.sv").write_text((BOARD / "tests/wrapper/tb.sv").read_text())
                    sources = [BOARD / "board_specific_top.sv", BOARD / "brs100_lcd.sv",
                               REPO / "labs/2_graphics/2_3_color_stripes/lab_top.sv",
                               *peripheral.glob("*.sv")]
                    run("iverilog", "-g2012", "-s", "tb", "-I", tmp, "-I", BOARD,
                        "-I", REPO / "labs/common", "-I", peripheral,
                        "-o", tmp / "board.vvp", tmp / "tb.sv", *sources)
                    self.assertIn("PASS wrapper", run("vvp", tmp / "board.vvp"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
