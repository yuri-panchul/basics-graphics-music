"""Run with python3 scripts/tests/test_board_specific_tcl.py; Vivado is not required.

The Vivado scripts read the sources and the constraints of boards/<fpga_board>,
taking fpga_board from the board's own board_specific.tcl. A directory copied
from another board that still names the original there builds the original's
files. These tests run the check in 00_setup_xilinx.source_bash that stops
such a build, against every board in the repository and against made-up ones.
"""

from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
BOARDS = REPO / "boards"
SCRIPT = REPO / "scripts/steps/00_setup_xilinx.source_bash"
RETIRED = "zzz_postponed_and_retired"


class CheckRunner:
    """Sources the real script from a file named as it expects and runs the check."""

    def __init__(self, directory):
        self.runner = Path(directory) / "00_setup.source_bash"
        self.runner.write_text(
            'set -Eeuo pipefail\n'
            'error () { printf "ERROR: %s\\n" "$*" >&2; exit 1; }\n'
            f'source {shlex.quote(str(SCRIPT))}\n'
            'xilinx_check_board_specific_tcl\n'
        )

    def run(self, board_dir, fpga_board):
        return subprocess.run(
            ["bash", str(self.runner)],
            env={"PATH": "/usr/bin:/bin", "board_dir": str(board_dir),
                 "fpga_board": fpga_board},
            capture_output=True, text=True,
        )


def boards_that_set_fpga_board():
    """Board directories whose board_specific.tcl sets fpga_board, the Xilinx ones."""
    return sorted(
        tcl.parent.name
        for tcl in BOARDS.glob("*/board_specific.tcl")
        if tcl.parent.name != RETIRED and "fpga_board" in tcl.read_text()
    )


class RepositoryTests(unittest.TestCase):
    def test_every_xilinx_board_names_its_own_directory(self):
        boards = boards_that_set_fpga_board()
        self.assertGreater(len(boards), 10, "the board scan found too few boards")

        with tempfile.TemporaryDirectory(prefix="board-tcl-") as temp:
            runner = CheckRunner(temp)
            failures = []

            for board in boards:
                result = runner.run(BOARDS, board)

                if result.returncode != 0:
                    failures.append(f"{board}: {result.stderr.strip()}")

        self.assertEqual(failures, [], "\n" + "\n".join(failures))


class CheckTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="board-tcl-")
        self.addCleanup(temp.cleanup)
        self.boards = Path(temp.name) / "boards"
        self.runner = CheckRunner(temp.name)

    def board(self, name, tcl):
        directory = self.boards / name
        directory.mkdir(parents=True)
        (directory / "board_specific.tcl").write_bytes(tcl.encode())
        return self.runner.run(self.boards, name)

    def test_matching_name_passes(self):
        result = self.board("some_board", "set fpga_board  some_board\nset part_name x\n")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_copied_directory_fails_and_says_what_to_write(self):
        result = self.board("some_board_hdmi", "set fpga_board  some_board\n")
        self.assertEqual(result.returncode, 1)
        self.assertIn('sets fpga_board to "some_board"', result.stderr)
        self.assertIn("Change that line to: set fpga_board some_board_hdmi", result.stderr)

    def test_prefix_of_the_directory_name_is_not_enough(self):
        result = self.board("nexys_a7_50", "set fpga_board nexys_a7\n")
        self.assertEqual(result.returncode, 1)

    def test_windows_line_endings_pass(self):
        result = self.board("some_board", "set fpga_board  some_board\r\nset part_name x\r\n")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_any_white_space_and_no_final_newline_pass(self):
        result = self.board("some_board", "  set\tfpga_board \t some_board")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_last_setting_wins_as_in_tcl(self):
        stale_last = self.board("board_a", "set fpga_board board_a\nset fpga_board board_b\n")
        self.assertEqual(stale_last.returncode, 1)

        fixed_last = self.board("board_c", "set fpga_board board_b\nset fpga_board board_c\n")
        self.assertEqual(fixed_last.returncode, 0, fixed_last.stderr)

    def test_missing_setting_fails(self):
        result = self.board("some_board", "set part_name x\n")
        self.assertEqual(result.returncode, 1)
        self.assertIn('sets fpga_board to ""', result.stderr)


if __name__ == "__main__":
    unittest.main()
