"""Run with python3 scripts/tests/test_fpga_board_menu.py; no FPGA toolchain
is required.

The main purpose of this test is to check that the two-level board menu of
scripts/steps/00_setup.source_bash offers exactly the same set of boards as
the one-level menu it replaced: every directory under "boards" has to be
reachable through exactly one pair of menu choices, and no pair of choices
may produce anything else.
"""

import os
from pathlib import Path
import re
import shlex
import subprocess
import unittest


REPO = Path(__file__).resolve().parents[2]
SETUP = REPO / "scripts/steps/00_setup.source_bash"
BOARD_DIR = REPO / "boards"

SECTION_BEGIN = "#   Two-level FPGA board menu"
SECTION_END = "#   FPGA board setup"

# Messages the menu prints; see "info" calls in select_fpga_board

CONFIG_PROMPT = "Please select a configuration of the board "
INVALID_BOARD = "Invalid FPGA board choice"
NOT_SELECTED = "a new FPGA board is not selected"


def menu_source():
    """The two-level menu section of 00_setup.source_bash, verbatim.

    Taking the text out of the real script rather than copying it here means
    the test cannot drift away from the code it checks.
    """

    lines = SETUP.read_text(encoding="utf-8").splitlines(keepends=True)
    begin = end = None

    for i, line in enumerate(lines):
        if line.rstrip("\n") == SECTION_BEGIN:
            begin = i
        elif line.rstrip("\n") == SECTION_END:
            end = i
            break

    if begin is None or end is None or end <= begin:
        raise AssertionError(
            "cannot find the menu section between %r and %r in %s"
            % (SECTION_BEGIN, SECTION_END, SETUP))

    # Back up over the banner lines of each section comment

    while begin > 0 and lines[begin - 1].startswith("#"):
        begin -= 1

    while end > 0 and lines[end - 1].startswith("#"):
        end -= 1

    text = "".join(lines[begin:end])

    for name in ("fpga_board_config_suffixes=",
                 "fpga_board_base ()",
                 "select_fpga_board ()"):
        if name not in text:
            raise AssertionError("%r is missing from the extracted section"
                                 % name)

    return text


MENU = menu_source()


def board_dirs():
    """The board list the way 00_setup.source_bash builds it: the
    directories under "boards", sorted. This is what the original one-level
    menu offered."""

    names = [e.name for e in os.scandir(BOARD_DIR) if e.is_dir()]
    return sorted(names)


class MenuRunner:
    """Runs select_fpga_board out of the real script with a given board list
    and a given sequence of menu answers."""

    def __init__(self, boards):
        self.boards = list(boards)

    def run(self, answers):
        runner = (
            'set -Eeuo pipefail\n'
            'info () { printf "%s\\n" "$*" 1>&2 ; }\n'
            'warning () { info "WARNING: $*" ; }\n'
            'error () { info "ERROR: $*" ; exit 1 ; }\n'
            'board_dir=' + shlex.quote(str(BOARD_DIR)) + '\n'
            'current_board_message=\n'
            'available_fpga_boards=' + shlex.quote(" ".join(self.boards)) + '\n'
            + MENU +
            'select_fpga_board\n'
            'printf "SELECTED=%s\\n" "$fpga_board"\n'
        )

        done = subprocess.run(
            ["bash", "-c", runner],
            input="".join("%s\n" % a for a in answers),
            capture_output=True, text=True)

        match = re.search(r"^SELECTED=(.*)$", done.stdout, re.M)

        return (match.group(1) if match else None), done.stderr

    def selected(self, answers):
        return self.run(answers)[0]

    def walk(self):
        """Every reachable board, as {board: [(answers), ...]}, by walking the
        menu the way a user would: the numbers are the only input, and the
        board names come back from the menu itself."""

        reached = {}
        first = 1

        while True:
            board, text = self.run([first])

            if board is not None:
                # A board with a single configuration: chosen in one step

                reached.setdefault(board, []).append((first,))
            elif CONFIG_PROMPT in text:
                # A board with several configurations: walk the second level
                # until the answer is no longer a configuration. The entries
                # after the configurations are "back" and "exit", and both
                # end without a selection.

                second = 1

                while True:
                    board = self.selected([first, second])

                    if board is None:
                        break

                    reached.setdefault(board, []).append((first, second))
                    second += 1

                    if second > 1000:
                        raise AssertionError("runaway second menu level")
            else:
                # Past the last board: "exit" or an invalid number

                if INVALID_BOARD not in text and NOT_SELECTED not in text:
                    raise AssertionError(
                        "unexpected answer to menu choice %d:\n%s"
                        % (first, text))
                break

            first += 1

            if first > 1000:
                raise AssertionError("runaway first menu level")

        self.first_level_size = first - 1

        return reached


class EquivalenceTests(unittest.TestCase):
    """The two-level menu has to select the same boards as the one-level
    menu that listed every configuration."""

    @classmethod
    def setUpClass(cls):
        cls.boards = board_dirs()
        cls.runner = MenuRunner(cls.boards)
        cls.reached = cls.runner.walk()

    def test_every_board_is_reachable(self):
        self.assertEqual(sorted(self.reached), self.boards)

    def test_every_board_is_reachable_once(self):
        duplicated = {b: p for b, p in self.reached.items() if len(p) != 1}
        self.assertEqual(duplicated, {})

    def test_first_level_is_shorter_than_the_board_list(self):
        self.assertLess(self.runner.first_level_size, len(self.boards))

    def test_exit_on_the_first_level_selects_nothing(self):
        exit_item = self.runner.first_level_size + 1
        board, text = self.runner.run([exit_item])

        self.assertIsNone(board)
        self.assertIn(NOT_SELECTED, text)

    def test_back_on_the_second_level_returns_to_the_first(self):
        # tang_nano_9k has many configurations; "back" is the entry after
        # the last of them

        first = None

        for i in range(1, self.runner.first_level_size + 1):
            text = self.runner.run([i])[1]

            if CONFIG_PROMPT + "tang_nano_9k:" in text:
                first = i
                break

        self.assertIsNotNone(first, "tang_nano_9k is not in the first level")

        configs = len([b for b in self.boards
                       if b == "tang_nano_9k" or b.startswith("tang_nano_9k_")])

        board, text = self.runner.run([first, configs + 1, first])

        # "back" reprints the first level, and the board menu is asked again

        self.assertIsNone(board)
        self.assertEqual(text.count(CONFIG_PROMPT + "tang_nano_9k:"), 2)

    def test_invalid_number_is_rejected_and_asked_again(self):
        board, text = self.runner.run([0, 10 ** 6, 1])

        self.assertIn(INVALID_BOARD, text)
        self.assertIsNotNone(board)


class SeparateBoardTests(unittest.TestCase):
    """Boards that only look like configurations of each other must stay
    separate entries of the first menu level."""

    def first_level_labels(self, boards):
        runner = MenuRunner(boards)
        reached = runner.walk()
        labels = {}

        for board, paths in reached.items():
            labels.setdefault(paths[0][0], []).append(board)

        return [sorted(labels[i]) for i in sorted(labels)]

    def test_de0_family(self):
        boards = ["de0", "de0_cv", "de0_nano_vga666", "de0_nano_vga_pmod",
                  "de0_nano_soc_vga666", "de0_nano_soc_vga_pmod"]

        self.assertEqual(self.first_level_labels(boards), [
            ["de0"],
            ["de0_cv"],
            ["de0_nano_vga666", "de0_nano_vga_pmod"],
            ["de0_nano_soc_vga666", "de0_nano_soc_vga_pmod"],
        ])

    def test_de1_de2_and_omdazz(self):
        boards = ["de1", "de1_soc", "de2", "de2_115",
                  "omdazz", "omdazz_pmod_mic3",
                  "omdazz_epm570", "omdazz_epm570_quartus_13_1_or_older"]

        self.assertEqual(self.first_level_labels(boards), [
            ["de1"],
            ["de1_soc"],
            ["de2"],
            ["de2_115"],
            ["omdazz", "omdazz_pmod_mic3"],
            ["omdazz_epm570", "omdazz_epm570_quartus_13_1_or_older"],
        ])

    def test_boards_distinguished_by_a_number_are_separate(self):
        boards = ["nexys_a7", "nexys_a7_50", "nexys_a7_100",
                  "arty_a7_35", "arty_a7_35_pmod_mic3",
                  "arty_a7_100", "arty_a7_100_pmod_mic3",
                  "tang_mega_138k_lcd_480_272_tm1638",
                  "tang_mega_138k_pro_lcd_480_272_tm1638"]

        self.assertEqual(self.first_level_labels(boards), [
            ["arty_a7_100", "arty_a7_100_pmod_mic3"],
            ["arty_a7_35", "arty_a7_35_pmod_mic3"],
            ["nexys_a7"],
            ["nexys_a7_100"],
            ["nexys_a7_50"],
            ["tang_mega_138k_lcd_480_272_tm1638"],
            ["tang_mega_138k_pro_lcd_480_272_tm1638"],
        ])


class OverlappingSuffixTests(unittest.TestCase):
    """The suffixes overlap, so the split has to try all the combinations:
    _hdmi_no_tm1638 is a listed suffix, but no_hdmi_no_tm1638 is _no_hdmi
    plus _no_tm1638."""

    def base_of(self, board):
        runner = MenuRunner([board, board + "_tm1638"])
        text = runner.run([1])[1]
        match = re.search(re.escape(CONFIG_PROMPT) + r"(\S+):", text)

        self.assertIsNotNone(match, "no second menu level for %r" % board)

        return match.group(1)

    def test_no_hdmi(self):
        self.assertEqual(
            self.base_of("tang_primer_20k_dock_no_hdmi_no_tm1638"),
            "tang_primer_20k_dock")

    def test_no_dvi(self):
        self.assertEqual(
            self.base_of("icebreaker_no_dvi_no_tm1638_yosys"), "icebreaker")

    def test_pmod_with_a_separate_component(self):
        self.assertEqual(
            self.base_of("tang_primer_25k_pmod_hub75e_led_matrix_bright"),
            "tang_primer_25k")

    def test_50mhz_in_the_middle(self):
        self.assertEqual(
            self.base_of("tang_nano_9k_50mhz_hdmi_no_tm1638"), "tang_nano_9k")

    def test_a_name_without_a_suffix_is_its_own_base(self):
        self.assertEqual(self.base_of("de10_nano"), "de10_nano")


class ReservedNameTests(unittest.TestCase):
    """The menu items are chosen by number, not by the text of the label, so
    a board directory named like one of the menu commands is still
    selectable. The one-level menu it replaced compared the label text and
    could not select such a board."""

    def test_board_named_exit_on_the_first_level(self):
        runner = MenuRunner(["de0", "exit"])

        self.assertEqual(runner.selected([2]), "exit")

    def test_board_named_back_as_a_configuration(self):
        runner = MenuRunner(["zeowaa", "zeowaa_wo_dig_0", "back"])

        # 1) back  2) zeowaa (2 configurations)  3) exit

        self.assertEqual(runner.selected([1]), "back")
        self.assertEqual(runner.selected([2, 1]), "zeowaa")
        self.assertEqual(runner.selected([2, 2]), "zeowaa_wo_dig_0")

    def test_exit_still_works_next_to_a_board_named_exit(self):
        runner = MenuRunner(["de0", "exit"])
        board, text = runner.run([3])

        self.assertIsNone(board)
        self.assertIn(NOT_SELECTED, text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
