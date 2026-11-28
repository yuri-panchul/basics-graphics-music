"""Run with python3 -B scripts/tests/test_icarus_file_list.py; requires Icarus."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts/steps/00_setup_icarus.source_bash"


@unittest.skipUnless(shutil.which("iverilog") and shutil.which("vvp"),
                     "iverilog and vvp are required")
class IcarusFileListTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="icarus-file-list-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo with spaces"
        self.lab = self.repo / "labs/1_basics/example lab"
        self.run = self.lab / "run"
        self.common = self.repo / "labs/common"
        self.peripherals = self.repo / "peripherals"
        for directory in (self.run, self.common, self.peripherals):
            directory.mkdir(parents=True)
        self.runner = self.root / "00_setup.source_bash"
        # Source the production function through its required parent script.
        # Only tool installation, assembly, and UI messages are stubbed.
        self.runner.write_text(r'''set -Eeuo pipefail
warning () { printf 'WARNING: %s\n' "$*" >&2; }
is_command_available_or_error_and_install ()
{
    # These tests do not produce a VCD or launch a waveform viewer.

    test "$1" = iverilog
    command -v "$1" > /dev/null
}
rars_assembly ()
{
    test "$PWD" = "$TEST_RUN_DIR"
    printf '2a\n' > program.hex
}
source "$TEST_SCRIPT"
cd "$TEST_RUN_DIR"
run_icarus_verilog
test "$PWD" = "$TEST_RUN_DIR"
''')

    def write(self, path, contents):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)

    def make_tb(self, declarations="", checks=""):
        return '''module tb;
    reg [7:0] memory [0:0];
    integer result_file;
''' + declarations + '''
    initial begin
        $readmemh("program.hex", memory);
        if (memory[0] !== 8'h2a) $fatal(1, "wrong simulation directory");
''' + checks + '''
        result_file = $fopen("simulation_ran.txt", "w");
        $fwrite(result_file, "PASS\\n");
        $fclose(result_file);
        $display("SIMULATION_PASS");
        $finish;
    end
endmodule
'''

    def simulate(self):
        env = os.environ.copy()
        for name in ("BASH_ENV", "ENV", "CDPATH", "SHELLOPTS", "BASHOPTS"):
            env.pop(name, None)
        env.update(TEST_SCRIPT=str(SCRIPT), TEST_RUN_DIR=str(self.run),
                   package_dir=str(self.repo), lab_dir=str(self.repo / "labs"),
                   log=str(self.run / "log.txt"))
        return subprocess.run(["bash", str(self.runner)], env=env, cwd=self.root,
                              capture_output=True, text=True, timeout=20)

    def assert_simulated(self):
        result = self.simulate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("SIMULATION_PASS", result.stdout)
        self.assertEqual((self.run / "simulation_ran.txt").read_text(), "PASS\n")
        self.assertTrue((self.run / "a.out").is_file())
        self.assertFalse((self.lab / "a.out").exists())
        self.assertFalse((self.lab / "simulation_ran.txt").exists())

    def test_list_replaces_all_globs_and_preserves_package_order(self):
        self.write(self.lab / "rtl/z_package.sv",
                   "package values; parameter int ANSWER = 42; endpackage\n")
        self.write(self.lab / "rtl/a_design.sv", '''module core_under_test(output [7:0] value);
    import values::*;
    assign value = ANSWER;
endmodule
// This root would fail if the script stopped selecting only tb.
module unused;
    initial $fatal(1, "unexpected root");
endmodule
''')
        self.write(self.lab / "tb.sv", self.make_tb(
            "wire [7:0] value; core_under_test dut(value);",
            '#1; if (value !== 42) $fatal(1, "incorrect design value");'))
        for path in (self.lab / "unlisted.sv", self.lab / "unlisted.v",
                     self.common / "unlisted.sv", self.peripherals / "unlisted.sv"):
            self.write(path, "This unlisted source must not be compiled!\n")
        self.write(self.lab / "sv_file_list.f",
                   "rtl/z_package.sv\nrtl/a_design.sv\ntb.sv\n")
        self.assert_simulated()

    def test_native_format_comments_crlf_nested_lists_and_spaces(self):
        self.write(self.lab / "includes/value.svh", "`define VALUE 42\n")
        self.write(self.lab / "rtl/design file.v", '''`include "value.svh"
module core_under_test(output [7:0] value);
    assign value = `VALUE + `OFFSET;
endmodule
''')
        # Paths in nested lists are also relative to the lab directory.
        self.write(self.lab / "lists/design.f", "rtl/design file.v\n")
        self.write(self.lab / "tb.sv", self.make_tb(
            "wire [7:0] value; core_under_test dut(value);",
            '#1; if (value !== 43) $fatal(1, "command-file options lost");'))
        self.write(self.lab / "sv_file_list.f", '''# Hash comment

/* A block comment
   across lines. */
+incdir+includes
+define+OFFSET=1
-f lists/design.f
tb.sv // Trailing comment
'''.replace("\n", "\r\n"))
        self.assert_simulated()

    def test_default_includes_and_explicit_shared_and_absolute_sources(self):
        for directory, name, value in (
                (self.lab, "LAB", 1), (self.lab / "cpu", "CPU", 2),
                (self.run, "RUN", 3), (self.common, "COMMON", 4),
                (self.peripherals, "PERIPHERAL", 5)):
            self.write(directory / f"{name}.svh", f"`define {name} {value}\n")
        self.write(self.common / "common.sv", "module common_part; endmodule\n")
        self.write(self.peripherals / "peripheral.sv",
                   "module peripheral_part; endmodule\n")
        includes = "".join(f'`include "{name}.svh"\n'
                           for name in ("LAB", "CPU", "RUN", "COMMON", "PERIPHERAL"))
        self.write(self.lab / "tb.sv", includes + self.make_tb(
            "common_part c(); peripheral_part p();",
            'if (`LAB + `CPU + `RUN + `COMMON + `PERIPHERAL != 15) '
            '$fatal(1, "include paths lost");'))
        self.write(self.lab / "sv_file_list.f",
                   "../../common/common.sv\n../../../peripherals/peripheral.sv\n"
                   + str(self.lab / "tb.sv") + "\n")
        self.assert_simulated()

    def test_no_list_keeps_all_legacy_source_locations(self):
        for path, name in ((self.lab / "design.sv", "core_under_test"),
                           (self.lab / "legacy.v", "legacy"),
                           (self.common / "common.sv", "common_part"),
                           (self.peripherals / "peripheral.sv", "peripheral_part")):
            self.write(path, f"module {name}; endmodule\n")
        self.write(self.lab / "tb.sv", self.make_tb(
            "core_under_test d(); legacy l(); common_part c(); peripheral_part p();"))
        self.assert_simulated()

    def test_no_list_allows_empty_globs(self):
        self.write(self.lab / "tb.sv", self.make_tb())
        self.assert_simulated()

    def test_invalid_lists_fail_without_discovery_or_stale_simulation(self):
        self.write(self.lab / "tb.sv", self.make_tb())
        self.write(self.lab / "broken.sv", "module broken; this is invalid; endmodule\n")
        self.write(self.lab / "design.sv", "module core_under_test; endmodule\n")
        # Seed a runnable stale output. A compile failure must not execute it.
        stale_source = self.root / "stale.sv"
        stale_source.write_text('''module tb;
    integer file_handle;
    initial begin
        file_handle = $fopen("stale_simulation_ran.txt", "w");
        $fclose(file_handle);
    end
endmodule
''')
        stale = self.root / "stale.out"
        subprocess.run(["iverilog", "-s", "tb", "-o", str(stale), str(stale_source)],
                       check=True, capture_output=True, text=True, timeout=20)
        for contents in ("", "missing.sv\ntb.sv\n", "broken.sv\ntb.sv\n",
                         "design.sv\n", "-f missing.f\n"):
            with self.subTest(file_list=contents):
                shutil.copyfile(stale, self.run / "a.out")
                self.write(self.lab / "sv_file_list.f", contents)
                result = self.simulate()
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertNotIn("SIMULATION_PASS", result.stdout)
                self.assertFalse((self.run / "simulation_ran.txt").exists())
                self.assertFalse((self.run / "stale_simulation_ran.txt").exists())


if __name__ == "__main__":
    unittest.main()
