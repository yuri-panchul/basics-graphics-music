"""Exercise the real setup script without EDA tools or a physical board.

Run: python3 scripts/tests/test_board_menu.py
Optionally compare every selection with an original flat-menu setup script:
    python3 scripts/tests/test_board_menu.py --baseline /tmp/old_setup.source_bash
"""

import argparse
import csv
import io
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
SETUP = REPO / "scripts/steps/00_setup.source_bash"
CONFIGURATIONS = sorted(path.name for path in (REPO / "boards").iterdir() if path.is_dir())
CATALOG = {
    row["Board"]: row["FPGA Manufacturer"]
    for row in csv.DictReader(io.StringIO((REPO / "boards/README.csv").read_text().replace("\\r\\n", "\n")))
}
# These directories appeared in the original menu but are not catalog models.
MODELS = set(CATALOG) | {"nexys_a7", "zzz_postponed_and_retired"}
GROUPS = {}
for configuration in CONFIGURATIONS:
    matches = [model for model in MODELS
               if configuration == model or configuration.startswith(model + "_")]
    if not matches:
        raise ValueError(f"Add {configuration} to the independent board catalog before testing its grouping")
    model = max(matches, key=len)
    GROUPS.setdefault(model, []).append(configuration)

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
        for configuration in CONFIGURATIONS:
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

    def run_setup(self, choices="", script="06_choose_another_fpga_board.bash", ostype=None):
        wrapper = self.lab / script
        wrapper.write_text(
            (f"OSTYPE={shlex.quote(ostype)}\n" if ostype else "")
            + f"source {shlex.quote(str(self.setup))}\n"
            + 'printf "RESULT_BOARD=%s\\nRESULT_TOOLCHAIN=%s\\n" "$fpga_board" "$fpga_toolchain"\n'
        )
        env = os.environ.copy()
        for name in ("BASH_ENV", "ENV", "CDPATH"):
            env.pop(name, None)
        env.update(PATH="/usr/bin:/bin", LC_ALL="C", COLUMNS="120")
        return subprocess.run(["bash", str(wrapper)], input=choices, text=True,
                              capture_output=True, cwd=self.lab, env=env, timeout=15)

    def choices_for(self, configuration):
        model = next(model for model, variants in GROUPS.items() if configuration in variants)
        choices = f"{list(GROUPS).index(model) + 1}\n"
        if len(GROUPS[model]) > 1:
            choices += f"{GROUPS[model].index(configuration) + 1}\n"
        return choices

    def expected_file(self, configuration):
        return "".join(("" if name == configuration else "# ") + name + "\n"
                       for name in CONFIGURATIONS)

    def assert_selection(self, result, configuration):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"RESULT_BOARD={configuration}\n", result.stdout)
        self.assertEqual(self.selection.read_text(), self.expected_file(configuration))

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
                            CATALOG.get(model), "none")
                    self.assertIn(f"RESULT_TOOLCHAIN={toolchain}\n", result.stdout)

                    if BASELINE is not None:
                        self.setup.write_text(BASELINE)
                        try:
                            old = self.run_setup(f"{CONFIGURATIONS.index(configuration) + 1}\n")
                            self.assert_selection(old, configuration)
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
            "tang_nano_9k_lcd_800_480_tm1638_hackathon": "tang_nano_9k",
            "tang_nano_9k_lcd_ml6485_no_tm1638_yosys": "tang_nano_9k",
            "tang_nano_9k_hdmi_no_ip_tm1638": "tang_nano_9k",
            "tang_nano_9k_tm1638_sd": "tang_nano_9k",
            "de10_lite_tm1638_virtual_switches": "de10_lite",
            "icebreaker_no_dvi_no_tm1638_yosys": "icebreaker",
            "tang_primer_20k_dock_no_hdmi_tm1638": "tang_primer_20k_dock",
            "tang_primer_20k_dock_no_hdmi_no_tm1638": "tang_primer_20k_dock",
            "tang_primer_25k_pmod_hub75e_led_matrix_bright": "tang_primer_25k",
            "colorlight75b_tm1638_ecp5_yosys": "colorlight75b",
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
        chosen = "tang_nano_9k_lcd_480_272_tm1638_hackathon"
        (self.lab / "hackathon_top.sv").write_text(f"// Board configuration: {chosen}\n")
        result = self.run_setup(script="03_synthesize_for_fpga.bash")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"RESULT_BOARD={chosen}\n", result.stdout)
        self.assertIn("RESULT_TOOLCHAIN=gowin\n", result.stdout)
        self.assertNotIn("Please select", result.stderr)
        self.assertFalse(self.selection.exists())

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
