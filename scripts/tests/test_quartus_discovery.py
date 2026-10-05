"""Run with python3 scripts/tests/test_quartus_discovery.py; Quartus is not required."""

import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/steps/00_setup_intel_fpga.source_bash"
PART = "EP4CE6E22C8"


class DiscoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="quartus-discovery-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.runner = self.root / "00_setup.source_bash"
        self.runner.write_text(
            'set -Eeuo pipefail\n'
            'info () { printf "%s\\n" "$*" >&2; }\n'
            'warning () { info "WARNING: $*"; }\n'
            'error () { info "ERROR: $*"; exit 1; }\n'
            f'source {shlex.quote(str(SCRIPT))}\n'
            'eval "$TEST_COMMAND"\n'
        )

    def install(self, parent, vendor, version, edition="lite", parts=(PART,),
                metadata=True, bin_dir="bin", suffix="", reported=None):
        root = self.root / parent / vendor / version / "quartus"
        bin_path = root / bin_dir
        bin_path.mkdir(parents=True)
        reported = reported or version.replace("sp", ".")
        if metadata:
            (root / "version.txt").write_bytes(
                f"Version={reported}\r\n[ACDS]\r\nVersion={reported}\r\nEdition={edition}\r\n".encode()
            )
        labels = {"lite": "Lite Edition", "web": "Web Edition", "std": "Standard Edition",
                  "subscription": "Subscription Edition", "pro": "Pro Edition"}
        banner = f"Version {reported} Build 123 {labels.get(edition, edition)}"
        shell = bin_path / ("quartus_sh" + suffix)
        shell.write_text(
            '#!/bin/bash\nset -eu\n'
            f'if [ "$1" = --version ]; then printf "%s\\n" {shlex.quote(banner)}; exit; fi\n'
            'if [ "$1" != -t ]; then echo "Unexpected probe" >&2; exit 9; fi\n'
            'case "$3" in\n'
            + "|".join(parts or ("NOT_INSTALLED",))
            + ') printf "BGM_DEVICE_SUPPORTED=%s\\n" "$3" ;;\n'
            '*) exit 1 ;;\nesac\n'
        )
        shell.chmod(0o755)
        for name in ("quartus", "quartus_pgm"):
            tool = bin_path / (name + suffix)
            tool.write_text("#!/bin/bash\nexit 0\n")
            tool.chmod(0o755)
        return root

    def run_shell(self, command, **overrides):
        env = os.environ.copy()
        for name in ("QUARTUS_ROOTDIR", "INTEL_FPGA_HOME", "ALTERA_HOME", "QUARTUS_HOME",
                     "BASH_ENV", "ENV", "QUARTUS_64BIT"):
            env.pop(name, None)
        env.update(PATH="/usr/bin:/bin", TEST_COMMAND=command,
                   script_dir=str(REPO / "scripts"), board_dir=str(REPO / "boards"),
                   fpga_board="omdazz", exe="", USER="quartus_test")
        env.update({key: str(value) for key, value in overrides.items()})
        return subprocess.run(["/bin/bash", str(self.runner)], env=env, cwd=self.root,
                              text=True, capture_output=True, timeout=20)

    def choose(self, expected, **env):
        result = self.run_shell(
            'quartus_setup\nprintf "ROOT=%s\\nPATH=%s\\n" "$QUARTUS_ROOTDIR" "$PATH"\n'
            'test "$quartus_sh_full_real_path" = "$QUARTUS_ROOTDIR/$quartus_bin_dir/quartus_sh$exe"\n'
            'test "$choosen_version_dir/quartus" = "$QUARTUS_ROOTDIR"', **env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"ROOT={expected}\n", result.stdout)
        return result

    def test_new_altera_layout_and_actual_edition(self):
        winner = self.install("p", "altera_lite", "25.1std", reported="25.1std.0.1129")
        self.install("p", "intelFPGA_lite", "21.1", reported="21.1.1.850")
        self.choose(winner, ALTERA_HOME=self.root / "p")

    def test_lite_beats_newer_standard(self):
        winner = self.install("p", "intelFPGA_lite", "21.1")
        self.install("p", "altera_std", "25.1", "std")
        self.choose(winner, QUARTUS_HOME=self.root / "p")

    def test_vendor_name_does_not_determine_edition(self):
        self.install("p", "altera_lite", "26.1", "std")
        winner = self.install("p", "altera", "25.1", "lite")
        self.choose(winner, ALTERA_HOME=self.root / "p")

    def test_versions_are_numeric(self):
        self.install("p", "altera", "25.2")
        winner = self.install("p", "altera", "25.10")
        self.choose(winner, ALTERA_HOME=self.root / "p")

    def test_build_number_breaks_version_tie(self):
        self.install("p", "altera", "25.1", reported="25.1.0.9")
        winner = self.install("p", "intelFPGA", "25.1", reported="25.1.0.10")
        self.choose(winner, ALTERA_HOME=self.root / "p")

    def test_missing_device_package_falls_back(self):
        self.install("p", "altera", "25.1", parts=())
        winner = self.install("p", "altera", "21.1")
        result = self.choose(winner, ALTERA_HOME=self.root / "p")
        self.assertIn("Device database query failed", result.stderr)

    def test_cyclone_ii_and_iii_have_distinct_limits(self):
        older = self.install("p", "altera", "13.0sp1", "web", metadata=False,
                             parts=("EP2C20F484C7", "EP3C16F484C6"))
        newer = self.install("p", "altera", "13.1", "web", metadata=False,
                             reported="13.1.0", parts=("EP2C20F484C7", "EP3C16F484C6"))
        self.choose(older, ALTERA_HOME=self.root / "p", fpga_board="de1")
        self.choose(newer, ALTERA_HOME=self.root / "p", fpga_board="de0")

    def test_agilex_requires_pro(self):
        part = "A3CZ135BB18AE7S"
        self.install("p", "altera_lite", "25.1", parts=(part,))
        winner = self.install("p", "altera_pro", "26.1.1", "pro", parts=(part,))
        self.choose(winner, ALTERA_HOME=self.root / "p", fpga_board="de23_lite")

    def test_max10_rejects_old_release(self):
        part = "10M50DAF484C7G"
        self.install("p", "altera", "13.1", "web", parts=(part,))
        winner = self.install("p", "altera_lite", "21.1", parts=(part,))
        self.choose(winner, ALTERA_HOME=self.root / "p", fpga_board="de10_lite")

    def test_first_cyclone_web_vs_subscription(self):
        part = "EP1C12Q240C8"
        rejected = self.install("p", "altera", "13.0sp1", "web", parts=(part,))
        winner = self.install("p", "altera", "13.0", "subscription", metadata=False,
                              reported="13.0.0", parts=(part,))
        self.choose(winner, QUARTUS_ROOTDIR=rejected, ALTERA_HOME=self.root / "p",
                    fpga_board="marsohod_mcy112")

    def test_wrapper_specific_limit(self):
        part = "EPM570T100C5"
        older = self.install("p", "altera", "13.1", parts=(part,))
        newer = self.install("p", "altera_lite", "25.1", parts=(part,))
        self.choose(older, ALTERA_HOME=self.root / "p", fpga_board="omdazz_epm570_quartus_13_1_or_older")
        self.choose(newer, ALTERA_HOME=self.root / "p", fpga_board="omdazz_epm570")

    def test_root_override_precedes_path_and_parents(self):
        winner = self.install("p", "altera", "21.1", "std")
        other = self.install("p", "altera_lite", "25.1")
        self.choose(winner, QUARTUS_ROOTDIR=winner, PATH=f"{other}/bin:/usr/bin:/bin",
                    ALTERA_HOME=self.root / "p")

    def test_path_precedes_parent_override(self):
        winner = self.install("p", "altera", "21.1", "std")
        self.install("p", "altera_lite", "25.1")
        self.choose(winner, PATH=f"{winner}/bin:/usr/bin:/bin", ALTERA_HOME=self.root / "p")

    def test_path_wrapper_outside_installation_is_diagnosed(self):
        wrapper_dir = self.root / "custom_bin"
        wrapper_dir.mkdir()
        wrapper = wrapper_dir / "quartus"
        wrapper.write_text("#!/bin/bash\nexit 0\n")
        wrapper.chmod(0o755)
        winner = self.install("p", "altera", "25.1")
        result = self.choose(winner, PATH=f"{wrapper_dir}:/usr/bin:/bin", ALTERA_HOME=self.root / "p")
        self.assertIn("outside a quartus/bin", result.stderr)

    def test_parent_override_precedence(self):
        first = self.install("first", "altera", "21.1")
        second = self.install("second", "altera", "25.1")
        third = self.install("third", "altera", "26.1")
        self.choose(first, INTEL_FPGA_HOME=self.root / "first", ALTERA_HOME=self.root / "second",
                    QUARTUS_HOME=self.root / "third")
        self.choose(second, ALTERA_HOME=self.root / "second", QUARTUS_HOME=self.root / "third")
        self.choose(third, QUARTUS_HOME=self.root / "third")

    def test_invalid_root_override_falls_back(self):
        winner = self.install("p", "altera", "21.1")
        self.choose(winner, QUARTUS_ROOTDIR=self.root / "absent", ALTERA_HOME=self.root / "p")

    def test_incomplete_install_falls_back(self):
        broken = self.install("p", "altera", "26.1")
        (broken / "bin/quartus_pgm").unlink()
        winner = self.install("p", "altera", "25.1")
        self.choose(winner, ALTERA_HOME=self.root / "p")

    def test_symlink_and_path_deduplication(self):
        winner = self.install("p", "altera", "25.1")
        alias = self.root / "alias"
        alias.symlink_to(winner, target_is_directory=True)
        result = self.choose(winner, QUARTUS_ROOTDIR=alias,
                             PATH=f"{winner}/bin:/usr/bin:{winner}/bin:/bin:")
        self.assertIn(f"PATH={winner}/bin:/usr/bin:/bin:\n", result.stdout)

    def test_problematic_paths_warn_but_are_not_split(self):
        winner = self.install("space quote' $ cash!", "altera", "25.1")
        result = self.choose(winner, ALTERA_HOME=winner.parents[2])
        self.assertIn("contains spaces", result.stderr)
        self.assertIn("relocate", result.stderr)

    def test_safe_path_does_not_warn(self):
        winner = self.install("p-safe_1", "altera", "25.1")
        result = self.choose(winner, QUARTUS_ROOTDIR=winner)
        self.assertNotIn("contains spaces", result.stderr)

    def test_windows_bin64_and_bin_fallback(self):
        winner = self.install("p", "altera", "25.1", bin_dir="bin64", suffix=".exe")
        result = self.run_shell(
            'cygpath () { printf "%s\\n" "$2"; }\nOSTYPE=msys\nexe=.exe\n'
            'quartus_setup\nprintf "ROOT=%s\\n" "$QUARTUS_ROOTDIR"', QUARTUS_ROOTDIR=winner)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"ROOT={winner}\n", result.stdout)
        legacy = self.install("legacy", "altera", "13.1", bin_dir="bin", suffix=".exe")
        result = self.run_shell(
            'cygpath () { printf "%s\\n" "$2"; }\nOSTYPE=cygwin\nexe=.exe\n'
            'quartus_setup\ntest "$quartus_bin_dir" = bin', QUARTUS_ROOTDIR=legacy)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_standard_pro_ranking_for_overlapping_devices(self):
        command = '''
quartus_best_root=present
quartus_candidate_edition=Standard
quartus_best_edition=Pro
quartus_candidate_version=25.1
quartus_best_version=25.1
quartus_candidate_better
quartus_best_version=26.1
! quartus_candidate_better
quartus_candidate_version=27.1
quartus_candidate_better
quartus_candidate_edition=Lite
quartus_candidate_version=21.1
quartus_candidate_better
'''
        result = self.run_shell(command)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_default_parents_compete_as_one_pool(self):
        self.install("drive_c", "altera", "26.1", "std", suffix=".exe")
        winner = self.install("drive_d", "altera_lite", "21.1", suffix=".exe")
        result = self.run_shell('''
cygpath ()
{
    case "$2" in
        /c) printf '%s\\n' "$TEST_ROOT/drive_c" ;;
        /d) printf '%s\\n' "$TEST_ROOT/drive_d" ;;
        /e) printf '%s\\n' "$TEST_ROOT/drive_e" ;;
        *) printf '%s\\n' "$2" ;;
    esac
}
sort () { echo 'Windows sort must not be invoked' >&2; exit 9; }
OSTYPE=msys
exe=.exe
quartus_setup
printf 'ROOT=%s\\n' "$QUARTUS_ROOTDIR"
''', TEST_ROOT=self.root)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"ROOT={winner}\n", result.stdout)

    def test_unrecognized_edition_falls_back(self):
        self.install("p", "altera_lite", "99.1", "unrecognized")
        winner = self.install("p", "altera", "25.1")
        result = self.choose(winner, ALTERA_HOME=self.root / "p")
        self.assertIn("Cannot identify the Quartus edition", result.stderr)

    def test_bad_metadata_uses_banner(self):
        winner = self.install("p", "altera_lite", "25.1", reported="25.1.0")
        (winner / "version.txt").write_text("Version=broken\nEdition=lite\n")
        self.choose(winner, ALTERA_HOME=self.root / "p")

    def test_banner_without_patch_does_not_treat_build_as_patch(self):
        winner = self.install("p", "altera", "13.1", "web", metadata=False,
                              parts=("EP3C16F484C6",))
        self.choose(winner, ALTERA_HOME=self.root / "p", fpga_board="de0")

    def test_path_warning_character_examples(self):
        for char in (' ', '!', '$', '%', '@', '^', '&', '*', '<', '>', ',', '"', "'", '(', ')', 'é'):
            with self.subTest(character=char):
                result = self.run_shell('quartus_warn_install_path "$TEST_PATH"', TEST_PATH=f"/tools/{char}/quartus")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("unsupported", result.stderr)

    def test_all_active_quartus_boards_are_dispatched(self):
        setup = (REPO / "scripts/steps/00_setup.source_bash").read_text()
        start = setup.index("update_fpga_toolchain_var ()")
        end = setup.index("\n}\n", start) + 3
        function = setup[start:end]
        for qsf in sorted((REPO / "boards").glob("*/board_specific.qsf")):
            with self.subTest(board=qsf.parent.name):
                result = self.run_shell(function + '\nupdate_fpga_toolchain_var\ntest "$fpga_toolchain" = quartus',
                                        fpga_board=qsf.parent.name)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_unsupported_platform_fails_clearly(self):
        result = self.run_shell('OSTYPE=darwin26\nquartus_setup')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not support", result.stderr)

    def test_all_board_device_assignments_parse(self):
        for qsf in sorted((REPO / "boards").rglob("board_specific.qsf")):
            with self.subTest(board=qsf.parent.name):
                result = self.run_shell('quartus_read_target\ntest -n "$quartus_target_part"',
                                        fpga_board=qsf.parent.relative_to(REPO / "boards"))
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
