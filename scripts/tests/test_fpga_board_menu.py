"""Run with python3 scripts/tests/test_fpga_board_menu.py; no FPGA toolchain
and no board are required.

Two harnesses are used.

MenuSection drives only the menu code, lifted verbatim out of
scripts/steps/00_setup.source_bash. It can be given board lists that do not
exist on disk, and it walks the menu with nothing but menu numbers, so the
test never computes the grouping it is checking.

Sandbox builds a throwaway repository with stub toolchain modules and runs the
whole real setup script inside it. That covers what surrounds the menu: the
bytes of fpga_board_selection, the chosen toolchain, the saved-selection
bypass, the hackathon override, and cancellation. It also replays every
selection through the original flat menu, so the two-level menu is compared
against the thing it replaced rather than against my own expectations.
"""

import argparse
import csv
import io
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import unittest


REPO = Path(__file__).resolve().parents[2]
SETUP = REPO / "scripts/steps/00_setup.source_bash"
BOARD_DIR = REPO / "boards"
CATALOG_CSV = BOARD_DIR / "README.csv"

SECTION_BEGIN = "#   Two-level FPGA board menu"
SECTION_END = "#   FPGA board setup"

CONFIG_PROMPT = "Please select a configuration of the board "
INVALID_BOARD = "Invalid FPGA board choice"
INVALID_CONFIG = "Invalid configuration choice"
NOT_SELECTED = "a new FPGA board is not selected"

# Directories that the menu must not offer; see fpga_board_non_boards and the
# _hackathon case in select_fpga_board

NON_BOARDS = ("zzz_postponed_and_retired",)
HACKATHON_SUFFIX = "_hackathon"

# Suffixes that name the size of the FPGA; see fpga_board_size_suffixes

SIZE_SUFFIXES = ("_35", "_50", "_100")

STUBS = {
    "altera": ["quartus_setup", "altera_setup_questa"],
    "gowin": ["gowin_setup_ide"],
    "efinity": ["efinity_setup_ide"],
    "xilinx": ["xilinx_setup_vivado"],
    "libre_lane": ["librelane_setup"],
    "icarus": ["icarus_verilog_setup"],
    "yosys": ["setup_yosys"],
    "rars": ["rars_setup"],
    "riscv": ["riscv_software_toolchain_setup"],
    "terminal": [],
}

BASELINE = None


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

    while begin > 0 and lines[begin - 1].startswith("#"):
        begin -= 1

    while end > 0 and lines[end - 1].startswith("#"):
        end -= 1

    text = "".join(lines[begin:end])

    for name in ("fpga_board_config_suffixes=",
                 "fpga_board_size_suffixes=",
                 "fpga_board_non_boards=",
                 "fpga_board_legacy_aliases=",
                 "fpga_board_drop_non_boards ()",
                 "fpga_board_menu_choice ()",
                 "fpga_board_alias_target ()",
                 "fpga_board_base ()",
                 "select_fpga_board ()"):
        if name not in text:
            raise AssertionError("%r is missing from the extracted section"
                                 % name)

    return text


MENU = menu_source()


def all_directories():
    """Every directory under boards, the way the setup script scans it."""

    return sorted(e.name for e in os.scandir(BOARD_DIR) if e.is_dir())


def selectable_directories():
    """The directories the menu is expected to offer."""

    return [d for d in all_directories()
            if d not in NON_BOARDS and not d.endswith(HACKATHON_SUFFIX)]


def clean_env(locale="C"):
    env = os.environ.copy()

    for name in ("BASH_ENV", "ENV", "CDPATH"):
        env.pop(name, None)

    env.update(PATH="/usr/bin:/bin", LC_ALL=locale, COLUMNS="120")

    return env


class MenuSection:
    """Runs select_fpga_board out of the real script against a given board
    list and a given sequence of answers."""

    def __init__(self, boards, locale="C"):
        self.boards = list(boards)
        self.locale = locale

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
            'if select_fpga_board\n'
            'then\n'
            '    printf "SELECTED=%s\\n" "$fpga_board"\n'
            'else\n'
            '    printf "CANCELLED=%s\\n" "$?"\n'
            'fi\n'
            # The menu must not leave its prompt or its answer behind
            'printf "LEFTOVER_PS3=%s\\nLEFTOVER_REPLY=%s\\n" "${PS3-}" "${REPLY-}"\n'
        )

        done = subprocess.run(
            ["bash", "-c", runner],
            input="".join("%s\n" % a for a in answers),
            capture_output=True, text=True, env=clean_env(self.locale),
            timeout=60)

        selected = re.search(r"^SELECTED=(.*)$", done.stdout, re.M)
        cancelled = re.search(r"^CANCELLED=(.*)$", done.stdout, re.M)

        if selected is None and cancelled is None:
            raise AssertionError(
                "the menu neither selected nor cancelled; it crashed:\n%s\n%s"
                % (done.stdout, done.stderr))

        return (selected.group(1) if selected else None,
                done.stdout, done.stderr)

    def cancelled(self, answers):
        return "CANCELLED=" in self.run(answers)[1]

    def selected(self, answers):
        return self.run(answers)[0]

    def walk(self):
        """Every board reachable through the menu, as {board: [answers, ...]},
        found by answering numbers and reading what the menu says back."""

        reached = {}
        first = 1

        while True:
            board, _, text = self.run([first])

            if board is not None:
                reached.setdefault(board, []).append((first,))
            elif CONFIG_PROMPT in text:
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
                # Past the last board: the answer hit "exit", or it was out of
                # range and the menu asked again until the input ran out.
                # Either way select_fpga_board returned non-zero, which
                # MenuSection.run has already distinguished from a crash.

                break

            first += 1

            if first > 1000:
                raise AssertionError("runaway first menu level")

        self.first_level_size = first - 1

        return reached


class Sandbox:
    """A throwaway repository with the real setup script and stub toolchain
    modules, so the whole script can run without any EDA tool installed."""

    def __init__(self, root, boards=None, setup_text=None):
        self.root = Path(root)
        self.steps = self.root / "scripts/steps"
        self.steps.mkdir(parents=True)
        self.setup = self.steps / SETUP.name
        self.setup.write_text(setup_text or SETUP.read_text(encoding="utf-8"),
                              encoding="utf-8")

        for module, functions in STUBS.items():
            (self.steps / ("00_setup_%s.source_bash" % module)).write_text(
                "".join("%s () { :; }\n" % f for f in functions))

        for board in (boards if boards is not None else all_directories()):
            (self.root / "boards" / board).mkdir(parents=True)

        self.lab = self.root / "labs/example"
        self.lab.mkdir(parents=True)
        self.selection = self.root / "fpga_board_selection"

    def run(self, answers="", script="06_choose_another_fpga_board.bash",
            saved=None, hackathon=None, ostype=None, setup_text=None):
        if setup_text is not None:
            self.setup.write_text(setup_text, encoding="utf-8")

        if saved is None:
            if self.selection.exists():
                self.selection.unlink()
        else:
            self.selection.write_text(saved)

        top = self.lab / "hackathon_top.sv"

        if hackathon is None:
            if top.exists():
                top.unlink()
        else:
            top.write_text("// Board configuration: %s\n" % hackathon)

        wrapper = self.lab / script
        wrapper.write_text(
            (("OSTYPE=%s\n" % shlex.quote(ostype)) if ostype else "")
            + "source %s\n" % shlex.quote(str(self.setup))
            + 'printf "BOARD=%s\\nTOOLCHAIN=%s\\n" "$fpga_board" "$fpga_toolchain"\n')

        if isinstance(answers, (list, tuple)):
            answers = "".join("%s\n" % a for a in answers)

        done = subprocess.run(["bash", str(wrapper)], input=answers,
                              text=True, capture_output=True, cwd=self.lab,
                              env=clean_env(), timeout=60)

        fields = dict(re.findall(r"^(BOARD|TOOLCHAIN)=(.*)$", done.stdout, re.M))

        return dict(rc=done.returncode,
                    board=fields.get("BOARD"),
                    toolchain=fields.get("TOOLCHAIN"),
                    out=done.stdout, err=done.stderr,
                    file=(self.selection.read_text()
                          if self.selection.exists() else None))


class SandboxCase(unittest.TestCase):
    """A test case with one sandbox per class."""

    @classmethod
    def setUpClass(cls):
        import tempfile
        cls._temp = tempfile.TemporaryDirectory(prefix="bgm-board-menu-")
        cls.box = Sandbox(cls._temp.name)

    @classmethod
    def tearDownClass(cls):
        cls._temp.cleanup()

    def expected_file(self, chosen, boards=None):
        boards = boards if boards is not None else all_directories()
        boards = [b for b in boards if b not in NON_BOARDS]

        return "".join(("" if b == chosen else "# ") + b + "\n" for b in boards)


class EquivalenceTests(unittest.TestCase):
    """Every selectable directory has to stay reachable through the two
    levels, by exactly one pair of answers, and nothing else may be."""

    @classmethod
    def setUpClass(cls):
        cls.boards = all_directories()
        cls.menu = MenuSection(cls.boards)
        cls.reached = cls.menu.walk()

    def test_every_selectable_board_is_reachable(self):
        self.assertEqual(sorted(self.reached), selectable_directories())

    def test_every_board_is_reachable_once(self):
        self.assertEqual({b: p for b, p in self.reached.items()
                          if len(p) != 1}, {})

    def test_first_level_is_shorter_than_the_configuration_list(self):
        self.assertLess(self.menu.first_level_size,
                        len(selectable_directories()))

    def test_exit_on_the_first_level_cancels(self):
        board, out, err = self.menu.run([self.menu.first_level_size + 1])

        self.assertIsNone(board)
        self.assertIn("CANCELLED=1", out)

    def test_the_menu_leaves_no_ps3_or_reply_behind(self):
        out = self.menu.run([1])[1]

        self.assertIn("LEFTOVER_PS3=\n", out)
        self.assertIn("LEFTOVER_REPLY=\n", out)

    def test_back_on_the_second_level_returns_to_the_first(self):
        first = None

        for i in range(1, self.menu.first_level_size + 1):
            if CONFIG_PROMPT + "tang_nano_9k:" in self.menu.run([i])[2]:
                first = i
                break

        self.assertIsNotNone(first, "tang_nano_9k is not in the first level")

        configs = len([b for b in selectable_directories()
                       if b == "tang_nano_9k" or b.startswith("tang_nano_9k_")])
        board, out, err = self.menu.run([first, configs + 1, first])

        self.assertIsNone(board)
        self.assertEqual(err.count(CONFIG_PROMPT + "tang_nano_9k:"), 2)

    def test_invalid_number_is_rejected_and_asked_again(self):
        board, out, err = self.menu.run([0, 10 ** 6, 1])

        self.assertIn(INVALID_BOARD, err)
        self.assertIsNotNone(board)


class OrderTests(unittest.TestCase):
    """The first level is sorted by board name, the same way on every
    machine."""

    @staticmethod
    def items_of(text):
        """The items of one "select" menu, in menu order.

        "select" lays its items out in columns, so the numbers order them,
        not the lines."""

        items = re.findall(r"(?:^|\s)(\d+)\) (\S+)", text)
        numbered = {int(n): label for n, label in items}

        return [numbered[i] for i in sorted(numbered)]

    def first_level(self, locale="C"):
        """The first-level entries in menu order."""

        menu = MenuSection(all_directories(), locale=locale)
        text = menu.run([1])[2]

        # Keep only the first menu: answering 1 may open a second one

        text = text.split("Please select an FPGA board", 1)[1]
        text = text.split(CONFIG_PROMPT, 1)[0]

        return self.items_of(text)

    def test_de0_nano_precedes_de0_nano_soc(self):
        order = self.first_level()

        self.assertLess(order.index("de0_nano"), order.index("de0_nano_soc"),
                        "the first level is not sorted by board name")

    def test_the_first_level_is_in_byte_order(self):
        order = self.first_level()

        self.assertEqual(order[:-1], sorted(order[:-1]),
                         "expected byte order, with exit last")
        self.assertEqual(order[-1], "exit")

    def test_the_order_does_not_depend_on_the_locale(self):
        reference = self.first_level("C")

        for locale in ("en_US.UTF-8", "ru_RU.UTF-8"):
            with self.subTest(locale=locale):
                self.assertEqual(self.first_level(locale), reference)

    def test_the_configurations_are_in_order_too(self):
        # In byte order de23_lite comes before de2_115, so the group is
        # item 2; its configurations have to be in byte order as well

        menu = MenuSection(["de23_lite", "de2_115", "de2_115_tm1638"])
        text = menu.run([2])[2]

        self.assertIn(CONFIG_PROMPT + "de2_115:", text)

        # After the second menu the input runs out, which sends the menu
        # back to the first level and prints it again, so cut there

        second = text.split(CONFIG_PROMPT, 1)[1]
        second = second.split("Please select an FPGA board", 1)[0]
        items = self.items_of(second)

        self.assertEqual(items, ["de2_115", "de2_115_tm1638", "back", "exit"])


class FirstLevelLabelTests(unittest.TestCase):
    """The first level lists bare board names, with a star on the ones that
    open a second menu."""

    def labels_and_groups(self):
        boards = all_directories()
        menu = MenuSection(boards)
        reached = menu.walk()
        sizes = {}

        for board, paths in reached.items():
            sizes[paths[0][0]] = sizes.get(paths[0][0], 0) + 1

        text = menu.run([1])[2]
        text = text.split("Please select an FPGA board", 1)[1]
        text = text.split(CONFIG_PROMPT, 1)[0]
        labels = {int(n): label for n, label in
                  re.findall(r"(?:^|\s)(\d+)\) (\S+(?: \*)?)", text)}

        return labels, sizes

    def test_a_star_marks_exactly_the_boards_with_several_configurations(self):
        labels, sizes = self.labels_and_groups()

        for position, count in sizes.items():
            with self.subTest(item=position, label=labels[position]):
                self.assertEqual(labels[position].endswith(" *"), count > 1)

    def test_the_labels_carry_no_configuration_counts(self):
        labels, _ = self.labels_and_groups()

        for label in labels.values():
            self.assertNotIn("configurations", label)

    def test_a_single_configuration_board_is_listed_under_the_board_name(self):
        # karnix_ecp5_yosys is the only configuration of karnix_ecp5, so the
        # first level says karnix_ecp5 and selects the directory directly

        menu = MenuSection(["de0", "karnix_ecp5_yosys"])
        text = menu.run([1])[2]
        items = re.findall(r"(?:^|\s)\d+\) (\S+)", text)

        self.assertIn("karnix_ecp5", items)
        self.assertNotIn("karnix_ecp5_yosys", items)
        self.assertEqual(menu.selected([2]), "karnix_ecp5_yosys")

    def test_the_star_is_not_part_of_the_selected_name(self):
        menu = MenuSection(["de0_nano_vga666", "de0_nano_vga_pmod"])
        text = menu.run([1])[2]

        self.assertIn("de0_nano *", text)
        self.assertEqual(menu.selected([1, 1]), "de0_nano_vga666")


class IgnoredDirectoryTests(unittest.TestCase):
    """Directories that are not boards, and configurations that are chosen
    through hackathon_top.sv, must not appear in the menu."""

    def test_non_board_directory_is_not_offered(self):
        menu = MenuSection(["de0", "zzz_postponed_and_retired"])
        reached = menu.walk()

        self.assertEqual(sorted(reached), ["de0"])

    def test_hackathon_configuration_is_not_offered(self):
        menu = MenuSection(["tang_nano_9k_hdmi_tm1638",
                            "tang_nano_9k_lcd_480_272_tm1638_hackathon"])
        reached = menu.walk()

        self.assertEqual(sorted(reached), ["tang_nano_9k_hdmi_tm1638"])

    def test_a_board_whose_only_configuration_is_hackathon_disappears(self):
        menu = MenuSection(["de0", "only_board_tm1638_hackathon"])

        self.assertEqual(sorted(menu.walk()), ["de0"])


class BoardFamilyTests(unittest.TestCase):
    """Which directories count as one board."""

    def families(self, boards):
        """The grouping, as a list of groups sorted by their contents. The
        order of the menu is deliberately not part of this: it is checked
        separately, so these tests survive a change of menu order."""

        reached = MenuSection(boards).walk()
        by_first = {}

        for board, paths in reached.items():
            by_first.setdefault(paths[0][0], []).append(board)

        return sorted(sorted(group) for group in by_first.values())

    def test_nexys_a7_is_one_board_with_three_configurations(self):
        self.assertEqual(
            self.families(["nexys_a7", "nexys_a7_50", "nexys_a7_100"]),
            [["nexys_a7", "nexys_a7_100", "nexys_a7_50"]])

    def test_nexys_a7_alias_is_labelled_in_the_second_level(self):
        menu = MenuSection(["nexys_a7", "nexys_a7_50", "nexys_a7_100"])
        text = menu.run([1])[2]

        self.assertIn("nexys_a7 (alias of nexys_a7_100)", text)
        self.assertNotIn("nexys_a7_50 (alias", text)

    def test_arty_a7_is_one_board_with_four_configurations(self):
        self.assertEqual(
            self.families(["arty_a7_35", "arty_a7_35_pmod_mic3",
                           "arty_a7_100", "arty_a7_100_pmod_mic3"]),
            [["arty_a7_100", "arty_a7_100_pmod_mic3",
              "arty_a7_35", "arty_a7_35_pmod_mic3"]])

    def test_nexys4_and_nexys4_ddr_stay_separate(self):
        self.assertEqual(self.families(["nexys4", "nexys4_ddr"]),
                         [["nexys4"], ["nexys4_ddr"]])

    def test_de0_family(self):
        self.assertEqual(
            self.families(["de0", "de0_cv", "de0_nano_vga666",
                           "de0_nano_vga_pmod", "de0_nano_soc_vga666",
                           "de0_nano_soc_vga_pmod"]),
            sorted([["de0"], ["de0_cv"],
                     ["de0_nano_soc_vga666", "de0_nano_soc_vga_pmod"],
                     ["de0_nano_vga666", "de0_nano_vga_pmod"]]))

    def test_de1_de2_and_omdazz(self):
        self.assertEqual(
            self.families(["de1", "de1_soc", "de2", "de2_115",
                           "omdazz", "omdazz_pmod_mic3", "omdazz_epm570",
                           "omdazz_epm570_quartus_13_1_or_older"]),
            sorted([["de1"], ["de1_soc"], ["de2"], ["de2_115"],
                     ["omdazz", "omdazz_pmod_mic3"],
                     ["omdazz_epm570",
                      "omdazz_epm570_quartus_13_1_or_older"]]))

    def test_ecp5_stays_in_the_board_name(self):
        # The directories were renamed so that _ecp5 comes before _tm1638;
        # it names the FPGA, not a configuration, and must survive

        self.assertEqual(
            self.families(["colorlight75b_ecp5_tm1638_yosys",
                           "karnix_ecp5_yosys"]),
            [["colorlight75b_ecp5_tm1638_yosys"], ["karnix_ecp5_yosys"]])

        text = MenuSection(["karnix_ecp5_yosys", "de0"]).run([2])[2]

        self.assertNotIn(CONFIG_PROMPT, text)


class SuffixTests(unittest.TestCase):
    """The suffixes overlap, so the split has to try all the combinations:
    _hdmi_no_tm1638 is a listed suffix, but no_hdmi_no_tm1638 is _no_hdmi
    plus _no_tm1638."""

    def base_of(self, board):
        menu = MenuSection([board, board + "_tm1638"])
        text = menu.run([1])[2]
        match = re.search(re.escape(CONFIG_PROMPT) + r"(\S+):", text)

        self.assertIsNotNone(match, "no second menu level for %r" % board)

        return match.group(1)

    def test_no_hdmi(self):
        self.assertEqual(
            self.base_of("tang_primer_20k_dock_no_hdmi_no_tm1638"),
            "tang_primer_20k_dock")

    def test_no_dvi(self):
        self.assertEqual(self.base_of("icebreaker_no_dvi_no_tm1638_yosys"),
                         "icebreaker")

    def test_pmod_compound(self):
        self.assertEqual(
            self.base_of("tang_primer_25k_pmod_hub75e_led_matrix_bright"),
            "tang_primer_25k")

    def test_pmod_alone_is_not_a_suffix(self):
        # A bare trailing _pmod names a board, not a configuration

        self.assertEqual(self.base_of("new_board_pmod"), "new_board_pmod")

    def test_50mhz_in_the_middle(self):
        self.assertEqual(self.base_of("tang_nano_9k_50mhz_hdmi_no_tm1638"),
                         "tang_nano_9k")

    def test_a_name_without_a_suffix_is_its_own_base(self):
        self.assertEqual(self.base_of("de10_nano"), "de10_nano")


class DecimalInputTests(SandboxCase):
    """Bash select accepts 08, 010, " 8" and "+8". Arithmetic on a leading
    zero is octal, so the menu has to normalise the answer before using it."""

    def item(self, number, boards=None):
        """What the first level offers as item <number>."""

        menu = MenuSection(boards if boards is not None else all_directories())
        board, out, err = menu.run([number])

        if board is not None:
            return board

        match = re.search(re.escape(CONFIG_PROMPT) + r"(\S+):", err)
        self.assertIsNotNone(match, "item %s is neither board nor group" % number)

        return match.group(1)

    def test_leading_zero_selects_the_same_item(self):
        for padded, plain in (("08", 8), ("09", 9), ("010", 10), ("0010", 10)):
            with self.subTest(reply=padded):
                self.assertEqual(self.item(padded), self.item(plain))

    def test_blanks_and_plus_are_accepted_like_bash_does(self):
        for reply in (" 8", "8 ", "+8"):
            with self.subTest(reply=reply):
                self.assertEqual(self.item(reply), self.item(8))

    def test_leading_zero_on_the_second_level(self):
        boards = ["tang_nano_9k_hdmi_tm1638",
                  "tang_nano_9k_lcd_480_272_tm1638",
                  "tang_nano_9k_lcd_800_480_tm1638"]
        menu = MenuSection(boards)

        self.assertEqual(menu.selected([1, "03"]), boards[2])

    def test_zero_padded_back_and_exit(self):
        boards = ["de0", "de0_nano_vga666", "de0_nano_vga_pmod"]
        menu = MenuSection(boards)

        # second level of de0_nano: 1, 2 are configurations, 3 is back,
        # 4 is exit. A zero-padded "back" has to go back, not select a
        # configuration, and a zero-padded "exit" has to cancel.

        self.assertEqual(menu.selected([2, "03", 1]), "de0")
        self.assertIsNone(menu.selected([2, "04"]))
        self.assertIsNone(menu.selected(["02", "04"]))
        self.assertIsNone(menu.selected(["03"]))

    def test_the_whole_script_survives_a_leading_zero(self):
        # Before the fix, 08 raised "value too great for base" and, with a
        # selection file present, carried on with the old board and no
        # toolchain at all

        plain = self.box.run([8])
        padded = self.box.run([8], saved="# keep\nbasys3\n")
        octal = self.box.run(["08"], saved="# keep\nbasys3\n")

        self.assertEqual(plain["rc"], 0, plain["err"])
        self.assertEqual(octal["rc"], 0, octal["err"])
        self.assertNotIn("value too great", octal["err"])
        self.assertEqual(octal["board"], plain["board"])
        self.assertEqual(octal["toolchain"], plain["toolchain"])
        self.assertEqual(padded["board"], plain["board"])


class SetupIntegrationTests(SandboxCase):
    """The menu is only part of the job: the selection has to be written, the
    toolchain chosen, and a saved or hackathon selection has to win."""

    def first_item_board(self):
        return MenuSection(all_directories()).selected([1])

    def test_a_selection_is_written_and_a_toolchain_chosen(self):
        result = self.box.run([1])
        board = self.first_item_board()

        self.assertEqual(result["rc"], 0, result["err"])
        self.assertEqual(result["board"], board)
        self.assertEqual(result["file"], self.expected_file(board))
        self.assertNotEqual(result["toolchain"], "")

    def test_the_non_board_directory_is_absent_from_the_selection_file(self):
        result = self.box.run([1])

        for non_board in NON_BOARDS:
            self.assertNotIn(non_board, result["file"])

    def test_a_hackathon_configuration_is_listed_in_the_selection_file(self):
        # It cannot be chosen from the menu, but an expert may still
        # uncomment it by hand, so it has to stay in the file

        result = self.box.run([1])

        self.assertIn("# tang_nano_9k_lcd_480_272_tm1638_hackathon\n",
                      result["file"])

    def test_a_saved_selection_bypasses_the_menu(self):
        chosen = "tang_nano_9k_lcd_480_272_no_tm1638_yosys"
        saved = self.expected_file(chosen)
        result = self.box.run(script="03_synthesize_for_fpga.bash", saved=saved)

        self.assertEqual(result["rc"], 0, result["err"])
        self.assertEqual(result["board"], chosen)
        self.assertEqual(result["toolchain"], "yosys")
        self.assertNotIn("Please select", result["err"])
        self.assertEqual(result["file"], saved)

    def test_hackathon_top_bypasses_the_menu(self):
        chosen = "tang_nano_9k_lcd_480_272_tm1638_hackathon"
        result = self.box.run(script="03_synthesize_for_fpga.bash",
                              hackathon=chosen)

        self.assertEqual(result["rc"], 0, result["err"])
        self.assertEqual(result["board"], chosen)
        self.assertEqual(result["toolchain"], "gowin")
        self.assertNotIn("Please select", result["err"])
        self.assertIsNone(result["file"])

    def test_cancelling_leaves_an_existing_selection_alone(self):
        saved = "# keep this comment and my board\nbasys3\n"

        multi = None

        for i in range(1, 200):
            if CONFIG_PROMPT in MenuSection(all_directories()).run([i])[2]:
                multi = i
                break

        self.assertIsNotNone(multi, "no multi-configuration board found")

        for answers in ([], ["999999"], [multi, 999999], [multi]):
            with self.subTest(answers=answers):
                result = self.box.run(answers, saved=saved)

                self.assertEqual(result["rc"], 0, result["err"])
                self.assertIn(NOT_SELECTED, result["err"])
                self.assertEqual(result["file"], saved)

    def test_cancelling_creates_no_selection_file(self):
        result = self.box.run([])

        self.assertEqual(result["rc"], 0, result["err"])
        self.assertIsNone(result["file"])

    def test_the_run_directory_question_still_appears(self):
        board = self.first_item_board()
        # "read -p" prints its prompt only to a terminal, so the question
        # itself is invisible here; what matters is that the answer is still
        # consumed and the selection still written

        result = self.box.run([1, "n"],
                              script="check_setup_and_choose_fpga_board.bash")

        self.assertEqual(result["rc"], 0, result["err"])
        self.assertEqual(result["board"], board)
        self.assertEqual(result["file"], self.expected_file(board))

        # The trailing "n" must have been consumed by that question and not
        # taken for a board choice

        self.assertEqual(result["err"].count("Invalid FPGA board choice"), 0)

    def test_the_discovery_branches_all_find_the_boards(self):
        board = self.first_item_board()

        for ostype in ("linux-gnu", "msys", "cygwin", "darwin23"):
            with self.subTest(ostype=ostype):
                result = self.box.run([1], ostype=ostype)

                self.assertEqual(result["rc"], 0, result["err"])
                self.assertEqual(result["board"], board,
                                 "the %s branch listed something else" % ostype)


class CatalogTests(unittest.TestCase):
    """A second opinion on the grouping, taken from the board catalogue in
    boards/README.csv instead of from the suffix list. A grouping bug that
    the suffix list and the test agreed about would survive the walk above;
    it does not survive this."""

    def test_the_grouping_matches_the_catalogue(self):
        rows = list(csv.DictReader(io.StringIO(
            CATALOG_CSV.read_text(encoding="utf-8"))))
        models = set()

        for row in rows:
            model = row["Board"]

            for suffix in SIZE_SUFFIXES:
                if model.endswith(suffix):
                    model = model[:-len(suffix)]

            models.add(model)

        # nexys_a7 has no catalogue row of its own: it is the legacy alias

        models.add("nexys_a7")

        expected = {}

        for config in selectable_directories():
            matching = [m for m in models
                        if config == m or config.startswith(m + "_")]
            self.assertTrue(matching,
                            "%s matches no catalogue model; add a row to "
                            "boards/README.csv" % config)
            expected.setdefault(max(matching, key=len), []).append(config)

        reached = MenuSection(all_directories()).walk()
        actual = {}

        for board, paths in reached.items():
            actual.setdefault(paths[0][0], []).append(board)

        self.assertEqual(
            sorted(tuple(sorted(v)) for v in expected.values()),
            sorted(tuple(sorted(v)) for v in actual.values()))


class BaselineTests(SandboxCase):
    """The two-level menu against the flat menu it replaced. Run with
    --baseline <old 00_setup.source_bash> to enable; without it the test
    reports itself as skipped."""

    def test_every_board_selects_as_it_did_before(self):
        if BASELINE is None:
            raise unittest.SkipTest(
                "pass --baseline <path to the previous 00_setup.source_bash>")

        boards = all_directories()
        current = SETUP.read_text(encoding="utf-8")
        paths = MenuSection(boards).walk()
        mismatches = []
        removed = []

        for i, board in enumerate(boards, start=1):
            old = self.box.run([i], setup_text=BASELINE)

            # The flat menu listed the directories in order, so item i is
            # board i. If that is not so, the comparison below is meaningless.

            self.assertEqual(old["board"], board,
                             "the flat menu's item %d is not %s" % (i, board))

            if board not in paths:
                removed.append(board)
                continue

            new = self.box.run(paths[board][0], setup_text=current)

            # The selection file is compared through its one uncommented
            # line: the file as a whole legitimately differs now, because
            # the non-board directory is no longer listed in it.

            def chosen(result):
                lines = [l for l in (result["file"] or "").splitlines()
                         if l and not l.startswith("#")]
                return lines

            if (old["board"], old["toolchain"], chosen(old)) != \
               (new["board"], new["toolchain"], chosen(new)):
                mismatches.append((board, old["board"], old["toolchain"],
                                   new["board"], new["toolchain"]))

        self.assertEqual(mismatches, [])

        # The only boards the two-level menu no longer offers are the ones
        # it is meant not to offer

        self.assertEqual(sorted(removed),
                         sorted(list(NON_BOARDS)
                                + [b for b in boards
                                   if b.endswith(HACKATHON_SUFFIX)]))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--baseline", type=Path)
    options, rest = parser.parse_known_args()

    if options.baseline:
        BASELINE = options.baseline.read_text(encoding="utf-8")

    print("%d directories, %d of them selectable"
          % (len(all_directories()), len(selectable_directories())))
    unittest.main(argv=[sys.argv[0], *rest], verbosity=2)
