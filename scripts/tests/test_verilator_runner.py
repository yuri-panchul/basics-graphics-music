"""Test the real simulation dispatcher without FPGA tools or a GUI."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]


class VerilatorRunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bgm verilator ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        steps = self.root / "scripts/steps"
        steps.mkdir(parents=True)
        for name in ("02_simulate_rtl.source_bash", "02_simulate_verilator.source_bash"):
            shutil.copy(REPO / "scripts/steps" / name, steps)
        # Any accidental FPGA setup must fail this test.
        (steps / "00_setup.source_bash").write_text("exit 88\n")
        self.lab = self.root / "labs/example with spaces"
        self.lab.mkdir(parents=True)
        shutil.copy(REPO / "scripts/steps/local_redirect.template_bash",
                    self.lab / "02_simulate_rtl.bash")
        (self.lab / "tb.sv").write_text("module tb; initial #1 $finish; endmodule\n")
        common = self.root / "labs/common"
        common.mkdir()
        (common / "multiple_modules.sv").write_text("module differently_named; endmodule\n")
        self.tool = self.root / "fake verilator"
        self.tool.write_text('''#!/usr/bin/env python3
import os, pathlib, sys
if sys.argv[1:] == ["--version"]:
    print(os.environ.get("TEST_VERSION", "Verilator 5.030"))
    sys.exit(0)
pathlib.Path("arguments.txt").write_text("\\n".join(sys.argv[1:]))
if os.environ.get("TEST_BUILD_FAIL"):
    sys.exit(7)
pathlib.Path("obj_dir").mkdir(exist_ok=True)
p = pathlib.Path("obj_dir/sim_verilator")
p.write_text("#!/bin/sh\\nprintf waveform > dump.vcd\\nprintf '%s\\\\n' '" + os.environ.get("TEST_MESSAGE", "PASS") + "'\\nexit " + os.environ.get("TEST_RUN_STATUS", "0") + "\\n")
p.chmod(0o755)
''')
        self.tool.chmod(0o755)

    def run_lab(self, **overrides):
        env = dict(os.environ, SIMULATOR="verilator", SIM_HEADLESS="1",
                   VERILATOR=str(self.tool))
        env.update(overrides)
        return subprocess.run(["bash", "./02_simulate_rtl.bash"], cwd=self.lab,
                              env=env, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT)

    def test_build_run_trace_and_paths(self):
        result = self.run_lab()
        self.assertEqual(result.returncode, 0, result.stdout)
        run = self.lab / "run"
        self.assertTrue((run / "dump.vcd").is_file())
        args = (run / "arguments.txt").read_text().splitlines()
        self.assertIn("--timing", args)
        self.assertIn("--assert", args)
        self.assertIn("-I" + str(self.root / "labs/common"), args)
        self.assertIn("../tb.sv", args)
        library_index = args.index(str(self.root / "labs/common/multiple_modules.sv"))
        self.assertEqual(args[library_index - 1], "-v")
        self.assertNotIn("../*.v", args)
        self.assertIn("bind tb", (run / "verilator_trace.sv").read_text())

    def test_old_version_rejected_before_build(self):
        result = self.run_lab(TEST_VERSION="Verilator 4.028")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("5.x", result.stdout)
        self.assertFalse((self.lab / "run").exists())

    def test_unknown_version_rejected(self):
        result = self.run_lab(TEST_VERSION="unknown")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("required", result.stdout)

    def test_build_failure_does_not_execute_stale_binary(self):
        self.assertEqual(self.run_lab().returncode, 0)
        (self.lab / "run/dump.vcd").unlink()
        result = self.run_lab(TEST_BUILD_FAIL="1")
        self.assertEqual(result.returncode, 7, result.stdout)
        self.assertFalse((self.lab / "run/dump.vcd").exists())

    def test_simulation_failure_propagates(self):
        result = self.run_lab(TEST_RUN_STATUS="9")
        self.assertEqual(result.returncode, 9, result.stdout)

    def test_reported_failure_propagates(self):
        result = self.run_lab(TEST_MESSAGE="ERROR: unexpected result")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("Testbench reported a failure", result.stdout)

    def test_missing_testbench(self):
        (self.lab / "tb.sv").unlink()
        result = self.run_lab()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("needs a testbench", result.stdout)

    def test_invalid_jobs(self):
        result = self.run_lab(VERILATOR_JOBS="0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("positive integer", result.stdout)

    def test_unknown_simulator(self):
        result = self.run_lab(SIMULATOR="typo")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unknown SIMULATOR", result.stdout)

    def test_viewer_receives_dump_and_exercise_script(self):
        viewer = self.root / "fake viewer"
        viewer.write_text("#!/bin/sh\nprintf '%s\\n' \"$@\" > viewer-arguments.txt\n")
        viewer.chmod(0o755)
        (self.lab / "gtkwave.tcl").write_text("# test configuration\n")
        result = self.run_lab(SIM_HEADLESS="0", GTKWAVE=str(viewer))
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.lab / "run/viewer-arguments.txt").read_text().splitlines(),
                         ["dump.vcd", "--script", "../gtkwave.tcl"])

    def test_missing_viewer_keeps_successful_simulation(self):
        result = self.run_lab(SIM_HEADLESS="0", GTKWAVE=str(self.root / "missing viewer"))
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Waveform saved", result.stdout)

    def test_auto_preserves_original_setup(self):
        self.assertEqual(self.run_lab(SIMULATOR="auto").returncode, 88)


if __name__ == "__main__":
    unittest.main()
