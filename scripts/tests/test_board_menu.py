"""Exercise the real setup script without EDA tools or a physical board.

Run: python3 scripts/tests/test_board_menu.py
Optionally compare every selection with an original flat-menu setup script:
    python3 scripts/tests/test_board_menu.py --baseline /tmp/old_setup.source_bash
"""

import argparse
from collections import Counter
import csv
import io
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
SETUP = REPO / "scripts/steps/00_setup.source_bash"
ALL_CONFIGURATIONS = sorted(path.name for path in (REPO / "boards").iterdir() if path.is_dir())
CONFIGURATIONS = [name for name in ALL_CONFIGURATIONS
                  if name != "zzz_postponed_and_retired" and not name.endswith("_hackathon")]
CATALOG = {
    row["Board"]: row["FPGA Manufacturer"]
    for row in csv.DictReader(io.StringIO((REPO / "boards/README.csv").read_text().replace("\\r\\n", "\n")))
}
# Independent expected results: the catalog describes models, while the menu
# groups the specified chip families and keeps ECP5 in these board names.
MODELS = set(CATALOG) | {"nexys_a7"}
MENU_NAMES = {
    "colorlight75b": "colorlight75b_ecp5",
    "colorlightI5": "colorlightI5_ecp5",
    "karnix": "karnix_ecp5",
    "orangecrab": "orangecrab_ecp5",
    "nexys_a7_50": "nexys_a7",
    "nexys_a7_100": "nexys_a7",
    "arty_a7_35": "arty_a7",
    "arty_a7_100": "arty_a7",
}
CONFIGURATION_MODELS = {}
GROUPS = {}
for configuration in CONFIGURATIONS:
    matches = [model for model in MODELS
               if configuration == model or configuration.startswith(model + "_")]
    if not matches:
        raise ValueError(f"Add {configuration} to the independent board catalog before testing its grouping")
    model = max(matches, key=len)
    CONFIGURATION_MODELS[configuration] = model
    GROUPS.setdefault(MENU_NAMES.get(model, model), []).append(configuration)

BASELINE = None


class BoardMenuTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bgm-board-menu-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.steps = self.root / "scripts/steps"
        self.steps.mkdir(parents=True)
        self.setup = self.steps / SETUP.name
        self.setup.write_text(SETUP.read_text())
        for configuration in ALL_CONFIGURATIONS:
            (self.root / "boards" / configuration).mkdir(parents=True)
        self.lab = self.root / "labs/example"
        self.lab.mkdir(parents=True)
        self.selection = self.root / "fpga_board_selection"

        # Only EDA setup is stubbed. Discovery, menus, persistence, saved selection,
        # hackathon overrides, and toolchain dispatch all run from the actual script.
        stubs = {
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
        for module, functions in stubs.items():
            (self.steps / f"00_setup_{module}.source_bash").write_text(
                "".join(f"{name} () {{ :; }}\n" for name in functions)
            )

    def run_setup(self, choices="", script="06_choose_another_fpga_board.bash", ostype=None,
                  locale="C", columns="120", extra_env=None):
        wrapper = self.lab / script
        wrapper.write_text(
            (f"OSTYPE={shlex.quote(ostype)}\n" if ostype else "")
            + f"source {shlex.quote(str(self.setup))}\n"
            + 'printf "RESULT_BOARD=%s\\nRESULT_TOOLCHAIN=%s\\n" "$fpga_board" "$fpga_toolchain"\n'
        )
        env = os.environ.copy()
        for name in ("BASH_ENV", "ENV", "CDPATH"):
            env.pop(name, None)
        env.update(PATH="/usr/bin:/bin", LC_ALL=locale, COLUMNS=columns)
        env.update(extra_env or {})
        return subprocess.run(["bash", str(wrapper)], input=choices, text=True,
                              capture_output=True, cwd=self.lab, env=env, timeout=15)

    def choices_for(self, configuration):
        model = next(model for model, variants in GROUPS.items() if configuration in variants)
        choices = f"{list(GROUPS).index(model) + 1}\n"
        if len(GROUPS[model]) > 1:
            choices += f"{GROUPS[model].index(configuration) + 1}\n"
        return choices

    def expected_file(self, configuration, names=None):
        return "".join(("" if name == configuration else "# ") + name + "\n"
                       for name in (CONFIGURATIONS if names is None else names))

    def assert_selection(self, result, configuration, names=None):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"RESULT_BOARD={configuration}\n", result.stdout)
        self.assertEqual(self.selection.read_text(), self.expected_file(configuration, names))

    def test_every_original_configuration_remains_selectable(self):
        for model, variants in GROUPS.items():
            for configuration in variants:
                with self.subTest(configuration=configuration):
                    result = self.run_setup(self.choices_for(configuration))
                    self.assert_selection(result, configuration)
                    if configuration.endswith("_yosys"):
                        toolchain = "yosys"
                    elif model == "nexys_a7":
                        toolchain = "xilinx"
                    else:
                        toolchain = {"Altera": "quartus", "Xilinx": "xilinx", "Gowin": "gowin"}.get(
                            CATALOG.get(CONFIGURATION_MODELS[configuration]), "none")
                    self.assertIn(f"RESULT_TOOLCHAIN={toolchain}\n", result.stdout)

                    if BASELINE is not None:
                        self.setup.write_text(BASELINE)
                        try:
                            old = self.run_setup(f"{ALL_CONFIGURATIONS.index(configuration) + 1}\n")
                            self.assert_selection(old, configuration, ALL_CONFIGURATIONS)
                            self.assertEqual(old.stdout, result.stdout)
                        finally:
                            self.setup.write_text(SETUP.read_text())

    def test_grouping_keeps_distinct_models_and_unknown_suffixes(self):
        cases = {
            "de0": "de0",
            "de0_nano_soc_vga666": "de0_nano_soc",
            "de0_nano_vga_pmod": "de0_nano",
            "de1": "de1",
            "de1_soc": "de1_soc",
            "de2": "de2",
            "de2_115": "de2_115",
            "omdazz": "omdazz",
            "omdazz_epm570_quartus_13_1_or_older": "omdazz_epm570",
            "tang_nano_9k_50mhz_hdmi_no_tm1638": "tang_nano_9k",
            "new_board_hackathon": "new_board_hackathon",
            "tang_nano_9k_lcd_ml6485_no_tm1638_yosys": "tang_nano_9k",
            "tang_nano_9k_hdmi_no_ip_tm1638": "tang_nano_9k",
            "tang_nano_9k_tm1638_sd": "tang_nano_9k",
            "de10_lite_tm1638_virtual_switches": "de10_lite",
            "icebreaker_no_dvi_no_tm1638_yosys": "icebreaker",
            "tang_primer_20k_dock_no_hdmi_tm1638": "tang_primer_20k_dock",
            "tang_primer_20k_dock_no_hdmi_no_tm1638": "tang_primer_20k_dock",
            "tang_primer_25k_pmod_hub75e_led_matrix_bright": "tang_primer_25k",
            "colorlight75b_ecp5_tm1638_yosys": "colorlight75b_ecp5",
            "colorlightI5_ecp5_tm1638_yosys": "colorlightI5_ecp5",
            "karnix_ecp5_yosys": "karnix_ecp5",
            "orangecrab_ecp5_yosys": "orangecrab_ecp5",
            "nexys_a7": "nexys_a7",
            "nexys_a7_50": "nexys_a7",
            "nexys_a7_100": "nexys_a7",
            "arty_a7_35_pmod_mic3": "arty_a7",
            "arty_a7_100": "arty_a7",
            "nexys4": "nexys4",
            "nexys4_ddr": "nexys4_ddr",
            "new_board_pmod": "new_board_pmod",
            "new_board_50": "new_board_50",
            "new_board_100": "new_board_100",
            "new_board_unknown": "new_board_unknown",
            "new_hdmi_board": "new_hdmi_board",
            "new_board_hub75e_led_matrix": "new_board",
            "new_board_no_hdmi_no_tm1638_yosys": "new_board",
            "_yosys": "_yosys",
        }
        wrapper = self.lab / "test_helpers.bash"
        wrapper.write_text(
            f"source {shlex.quote(str(self.setup))}\n"
            'for configuration in "$@"\ndo\n'
            '    printf "%s\\t" "$configuration"\n'
            '    fpga_board_base_name "$configuration"\ndone\n'
        )
        env = os.environ.copy()
        for name in ("BASH_ENV", "ENV", "CDPATH"):
            env.pop(name, None)
        result = subprocess.run(["bash", str(wrapper), *cases], cwd=self.lab,
                                env=env, text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(dict(line.split("\t") for line in result.stdout.splitlines()), cases)

    def test_single_configuration_skips_variant_menu(self):
        result = self.run_setup(self.choices_for("basys3"))
        self.assert_selection(result, "basys3")
        self.assertNotIn("Please select a variant", result.stderr)

    def test_invalid_input_retries_each_level(self):
        board, variant = self.choices_for("icebreaker_dvi_24b_tm1638_yosys").splitlines()
        result = self.run_setup(f"0\n-1\nabc\n9999\n{board}\n0\n-1\nabc\n9999\n{variant}\n")
        self.assert_selection(result, "icebreaker_dvi_24b_tm1638_yosys")
        self.assertIn("Invalid FPGA board choice", result.stderr)
        self.assertIn("Invalid FPGA board variant", result.stderr)

    def test_back_redisplays_boards_without_saving_intermediate_choice(self):
        board = list(GROUPS).index("icebreaker") + 1
        back = len(GROUPS["icebreaker"]) + 1
        result = self.run_setup(f"{board}\n{back}\n" + self.choices_for("omdazz_pmod_mic3"))
        self.assert_selection(result, "omdazz_pmod_mic3")
        self.assertEqual(result.stderr.count("Please select an FPGA board:"), 2)

    def test_exit_and_eof_do_not_create_or_overwrite_selection(self):
        board = list(GROUPS).index("icebreaker") + 1
        back = len(GROUPS["icebreaker"]) + 1
        inputs = {
            "exit_board": f"{len(GROUPS) + 1}\n",
            "exit_variant": f"{board}\n{back + 1}\n",
            "eof_board": "",
            "eof_invalid_board": "invalid\n",
            "eof_variant": f"{board}\n",
            "eof_invalid_variant": f"{board}\ninvalid\n",
            "eof_after_back": f"{board}\n{back}\n",
        }
        original = "# Keep this comment and my selected board.\nbasys3\n"
        for existing in (False, True):
            for label, choices in inputs.items():
                with self.subTest(existing=existing, input=label):
                    if existing:
                        self.selection.write_text(original)
                    elif self.selection.exists():
                        self.selection.unlink()
                    result = self.run_setup(choices)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertNotIn("RESULT_BOARD=", result.stdout)
                    if existing:
                        self.assertEqual(self.selection.read_text(), original)
                    else:
                        self.assertFalse(self.selection.exists())

    def test_saved_selection_bypasses_menu(self):
        chosen = "tang_nano_9k_lcd_480_272_no_tm1638_yosys"
        contents = self.expected_file(chosen)
        self.selection.write_text(contents)
        result = self.run_setup(script="03_synthesize_for_fpga.bash")
        self.assert_selection(result, chosen)
        self.assertNotIn("Please select", result.stderr)
        self.assertEqual(self.selection.read_text(), contents)

    def test_initial_setup_retains_the_run_directory_question(self):
        result = self.run_setup(self.choices_for("basys3") + "n\n",
                                script="check_setup_and_choose_fpga_board.bash")
        self.assert_selection(result, "basys3")

    def test_hackathon_override_bypasses_menu_and_selection_file(self):
        for chosen in (name for name in ALL_CONFIGURATIONS if name.endswith("_hackathon")):
            with self.subTest(configuration=chosen):
                (self.lab / "hackathon_top.sv").write_text(f"// Board configuration: {chosen}\n")
                result = self.run_setup(script="03_synthesize_for_fpga.bash")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"RESULT_BOARD={chosen}\n", result.stdout)
                self.assertIn("RESULT_TOOLCHAIN=gowin\n", result.stdout)
                self.assertNotIn("Please select", result.stderr)
                self.assertFalse(self.selection.exists())

    @staticmethod
    def menus(result):
        menus = []
        for number, label in re.findall(r"^\s*(\d+)\) (.+)$", result.stderr, re.M):
            if number == "1":
                menus.append([])
            menus[-1].append(label)
        return menus

    def test_walk_menu_reaches_only_eligible_configurations_once(self):
        first_menu = self.menus(self.run_setup(columns="1"))[0]
        self.assertEqual(first_menu[-1], "exit")
        self.assertNotIn("zzz_postponed_and_retired", first_menu)
        reached = []
        for first in range(1, len(first_menu)):
            result = self.run_setup(f"{first}\n", columns="1")
            self.assertEqual(result.returncode, 0, result.stderr)
            selected = re.search(r"^RESULT_BOARD=(.*)$", result.stdout, re.M)
            if selected:
                reached.append(selected.group(1))
                continue
            variants = self.menus(result)[1]
            self.assertEqual(variants[-2:], ["back", "exit"])
            self.assertFalse(any("_hackathon" in label for label in variants))
            for second in range(1, len(variants) - 1):
                result = self.run_setup(f"{first}\n{second}\n")
                self.assertEqual(result.returncode, 0, result.stderr)
                selected = re.search(r"^RESULT_BOARD=(.*)$", result.stdout, re.M)
                self.assertIsNotNone(selected, result.stderr)
                reached.append(selected.group(1))
        self.assertEqual(Counter(reached), Counter(CONFIGURATIONS))

    def test_legacy_alias_label_does_not_change_saved_identifier(self):
        result = self.run_setup(self.choices_for("nexys_a7"))
        self.assert_selection(result, "nexys_a7")
        self.assertIn("nexys_a7 (alias of nexys_a7_100)", result.stderr)

    def test_numbers_with_leading_zero_are_decimal(self):
        for first in (8, 9, 10):
            group = list(GROUPS)[first - 1]
            result = self.run_setup(f"0{first}\n1\n")
            self.assert_selection(result, GROUPS[group][0])
        first = list(GROUPS).index("tang_nano_9k") + 1
        for second in (8, 9, 10):
            result = self.run_setup(f"{first}\n0{second}\n")
            self.assert_selection(result, GROUPS["tang_nano_9k"][second - 1])

    def test_menu_order_is_independent_of_callers_locale(self):
        locales = subprocess.check_output(["locale", "-a"], text=True).splitlines()
        original = self.menus(self.run_setup(columns="1"))[0]
        for locale in ("C.utf8", "en_US.utf8", "ru_RU.utf8"):
            if locale not in locales:
                continue
            with self.subTest(locale=locale):
                result = self.run_setup(columns="1", locale=locale)
                self.assertEqual(self.menus(result)[0], original)
                result = self.run_setup(self.choices_for("de0_nano_soc_vga666"), locale=locale)
                self.assert_selection(result, "de0_nano_soc_vga666")

    def run_helpers(self, body, choices=""):
        wrapper = self.lab / "test_helpers.bash"
        wrapper.write_text(f"source {shlex.quote(str(self.setup))}\n" + body)
        env = os.environ.copy()
        for name in ("BASH_ENV", "ENV", "CDPATH"):
            env.pop(name, None)
        env.update(PATH="/usr/bin:/bin", LC_ALL="C")
        return subprocess.run(["bash", str(wrapper)], input=choices, cwd=self.lab,
                              env=env, text=True, capture_output=True, timeout=15)

    def test_helper_cancellation_returns_and_preserves_prompt_state(self):
        for choices in ("2\n", ""):
            result = self.run_helpers(
                'PS3=original_prompt\nREPLY=original_reply\nfpga_board=original_board\n'
                'current_board_message=\navailable_fpga_boards=basys3\n'
                'fpga_board_sort_discovery\n'
                'if choose_fpga_board; then status=0; else status=$?; fi\n'
                'printf "AFTER=%s,%s,%s,%s,%s\\n" "$status" "$PS3" "$REPLY" "$fpga_board" "$LC_ALL"\n',
                choices)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("AFTER=1,original_prompt,original_reply,original_board,C", result.stdout)

    def test_no_eligible_configurations_reports_and_returns(self):
        result = self.run_helpers(
            'current_board_message=\navailable_fpga_boards="zzz_postponed_and_retired board_hackathon"\n'
            'fpga_board_sort_discovery\n'
            'if choose_fpga_board; then exit 9; else printf "RETURNED\\n"; fi\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No FPGA board configurations", result.stderr)
        self.assertIn("RETURNED", result.stdout)

    def test_sort_discovery_checks_behavior_and_preserves_locale(self):
        # Bash functions can shadow these command names without changing /usr/bin.
        cases = {
            "failed_first": ('/usr/bin/sort () { return 1; }\n', "/bin/sort"),
            "wrong_first": ('/usr/bin/sort () { printf "wrong order\\n"; }\n', "/bin/sort"),
            "path_fallback": ('/usr/bin/sort () { return 1; }\n/bin/sort () { return 1; }\n'
                              'sort () { command /usr/bin/sort "$@"; }\n', "sort"),
            "no_compatible_sort": ('/usr/bin/sort () { return 1; }\n/bin/sort () { return 1; }\n'
                                   'sort () { printf "wrong order\\n"; }\n', None),
        }
        for name, (fakes, expected) in cases.items():
            with self.subTest(case=name):
                result = self.run_helpers(fakes + 'LC_ALL=POSIX\n'
                    'if fpga_board_sort_discovery; then printf "SORT=%s\\n" "$board_sort_to_run"; '
                    'else printf "NO_SORT\\n"; fi\nprintf "LOCALE=%s\\n" "$LC_ALL"\n')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("LOCALE=POSIX", result.stdout)
                if expected:
                    self.assertIn(f"SORT={expected}\n", result.stdout)
                else:
                    self.assertIn("NO_SORT", result.stdout)
                    self.assertIn("no Unix-compatible sort", result.stderr)

    def test_windows_sort_on_path_does_not_replace_unix_sort(self):
        tools = self.root / "fake-tools"
        tools.mkdir()
        fake_sort = tools / "sort"
        fake_sort.write_text('#!/bin/sh\nprintf "WINDOWS_SORT_USED\\n" >&2\nexit 1\n')
        fake_sort.chmod(0o755)
        result = self.run_setup(self.choices_for("nexys_a7_50"),
                                extra_env={"PATH": f"{tools}:/usr/bin:/bin"})
        self.assert_selection(result, "nexys_a7_50")
        self.assertNotIn("WINDOWS_SORT_USED", result.stderr)

    def test_platform_discovery_branches(self):
        for ostype in ("linux-gnu", "msys", "cygwin", "darwin23"):
            with self.subTest(ostype=ostype):
                result = self.run_setup(self.choices_for("de0_nano_soc_vga666"), ostype=ostype)
                self.assert_selection(result, "de0_nano_soc_vga666")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--baseline", type=Path)
    options, unittest_args = parser.parse_known_args()
    if options.baseline:
        BASELINE = options.baseline.read_text()
    print(f"Checking {len(CONFIGURATIONS)} configurations across {len(GROUPS)} board groups.")
    unittest.main(argv=[sys.argv[0], *unittest_args])
