#!/usr/bin/env python3
"""Run the real ASIC launchers with recording tools; no PDK or GUI required."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
LAB = Path('labs/1_basics/1_01_and_or_not_xor_de_morgan')
SYNTH = '07_synthesize_for_asic.bash'
VIEWERS = {
    '08_visualize_asic_synthesis_results_1.bash': 'OpenInOpenROAD',
    '09_visualize_asic_synthesis_results_2.bash': 'OpenInKLayout',
}
TOOL = '''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['TEST_CALLS'], 'a') as stream:
    stream.write(json.dumps({'executable': sys.argv[0], 'args': sys.argv[1:],
                             'cwd': os.getcwd()}) + '\\n')
sys.exit(int(os.environ.get('TEST_EXIT', '0')))
'''


class LibreLaneLaunchers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='librelane-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        # No .git directory: the same launchers must work in source archives.
        self.root = self.base / 'checkout with spaces'
        shutil.copytree(REPO / 'scripts', self.root / 'scripts')
        shutil.copytree(REPO / 'labs/common', self.root / 'labs/common')
        shutil.copytree(REPO / LAB, self.root / LAB, ignore=shutil.ignore_patterns('run'))
        self.lab = self.root / LAB
        self.design = self.root / 'librelane_designs' / LAB.name
        self.calls = self.base / 'calls.jsonl'
        self.appimage = self.base / 'tools with spaces' / 'LibreLane;touch SHOULD_NOT_EXIST.AppImage'
        self.tool(self.appimage)
        self.env = dict(os.environ)
        for name in ('LIBRELANE_APPIMAGE', 'LIBRELANE_PATH', 'TEST_CALLS', 'TEST_EXIT'):
            self.env.pop(name, None)
        self.env.update(LIBRELANE_APPIMAGE=str(self.appimage), TEST_CALLS=str(self.calls))

    def tool(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(TOOL)
        path.chmod(0o755)

    def launch(self, entry=SYNTH, *args, expected=0):
        self.calls.unlink(missing_ok=True)
        result = subprocess.run(['bash', str(self.lab / entry), *args], cwd=self.lab,
                                env=self.env, input='', text=True, capture_output=True,
                                timeout=20)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []
        return result, calls

    def test_appimage_synthesis_preserves_arguments_and_working_directory(self):
        tag = 'run with spaces;$(touch SHOULD_NOT_EXIST)'
        _, calls = self.launch(SYNTH, '--run-tag', tag, '--to', 'Checker.NetlistAssignStatements')
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0], {
            'executable': str(self.appimage), 'cwd': str(self.design),
            'args': ['librelane', '--flow', 'Classic', '--run-tag', tag,
                     '--to', 'Checker.NetlistAssignStatements', str(self.design / 'config.tcl')],
        })
        self.assertFalse(any(self.root.rglob('SHOULD_NOT_EXIST*')))

    def test_explicit_appimage_precedes_native_and_legacy_override(self):
        native = self.base / 'native' / 'librelane'
        self.tool(native)
        self.env['PATH'] = str(native.parent) + os.pathsep + self.env['PATH']
        self.env['LIBRELANE_PATH'] = str(native.parent)
        _, calls = self.launch()
        self.assertEqual(calls[0]['executable'], str(self.appimage))

    def test_native_shell_is_reused(self):
        native = self.base / 'native' / 'librelane'
        self.tool(native)
        del self.env['LIBRELANE_APPIMAGE']
        self.env['PATH'] = str(native.parent) + os.pathsep + self.env['PATH']
        _, calls = self.launch()
        self.assertEqual(calls[0]['executable'], str(native))
        self.assertEqual(calls[0]['args'][:2], ['--flow', 'Classic'])

    def test_legacy_directory_override_precedes_path(self):
        legacy = self.base / 'legacy tools' / 'librelane'
        other = self.base / 'other' / 'librelane'
        self.tool(legacy)
        self.tool(other)
        del self.env['LIBRELANE_APPIMAGE']
        self.env['LIBRELANE_PATH'] = str(legacy.parent)
        self.env['PATH'] = str(other.parent) + os.pathsep + self.env['PATH']
        _, calls = self.launch()
        self.assertEqual(calls[0]['executable'], str(legacy))

    def test_invalid_appimage_fails_without_fallback_or_staging(self):
        native = self.base / 'native' / 'librelane'
        self.tool(native)
        self.env['PATH'] = str(native.parent) + os.pathsep + self.env['PATH']
        for value in ('', str(self.base / 'missing'), str(self.base)):
            with self.subTest(value=value):
                self.env['LIBRELANE_APPIMAGE'] = value
                result, calls = self.launch(expected=1)
                self.assertIn('LIBRELANE_APPIMAGE must name an executable', result.stderr)
                self.assertEqual(calls, [])
                self.assertFalse(self.design.exists())

    def test_non_executable_appimage_is_rejected(self):
        self.appimage.chmod(0o644)
        result, calls = self.launch(expected=1)
        self.assertIn('LIBRELANE_APPIMAGE', result.stderr)
        self.assertEqual(calls, [])

    def test_invalid_legacy_path_is_rejected(self):
        del self.env['LIBRELANE_APPIMAGE']
        for value in ('', str(self.appimage), str(self.base / 'missing')):
            with self.subTest(value=value):
                self.env['LIBRELANE_PATH'] = value
                result, calls = self.launch(expected=1)
                self.assertIn('LIBRELANE_PATH must name a directory', result.stderr)
                self.assertEqual(calls, [])

    def test_synthesis_failure_propagates_without_success_banner(self):
        self.env['TEST_EXIT'] = '23'
        result, calls = self.launch(expected=23)
        self.assertEqual(len(calls), 1)
        self.assertNotIn('Done running', result.stdout + result.stderr)

    def test_staging_failure_prevents_tool_launch(self):
        (self.root / 'labs/common/config.svh').unlink()
        _, calls = self.launch(expected=1)
        self.assertEqual(calls, [])

    def test_staging_handles_unusual_filenames_and_lab_config(self):
        name = "quoted ' header\nwith spaces.svh"
        (self.lab / name).write_text('// fixture\n')
        config = (self.root / 'scripts/asic/config.tcl').read_text() + '\n# lab override\n'
        (self.lab / 'asic_config.tcl').write_text(config)
        self.launch()
        self.assertEqual((self.design / 'src' / name).read_text(), '// fixture\n')
        self.assertEqual((self.design / 'config.tcl').read_text(), config)
        self.assertTrue((self.design / 'src/define_gowin_or_nothing.svh').exists())
        self.assertFalse((self.design / 'src/tb.sv').exists())

    def test_viewers_default_to_last_run(self):
        self.launch()
        for entry, flow in VIEWERS.items():
            with self.subTest(viewer=flow):
                _, calls = self.launch(entry)
                self.assertEqual(calls, [{
                    'executable': str(self.appimage), 'cwd': str(self.design),
                    'args': ['librelane', '--flow', flow, '--last-run', './config.tcl'],
                }])

    def test_viewers_forward_explicit_run_and_state(self):
        self.launch()
        for entry, flow in VIEWERS.items():
            for selection in (['--run-tag', 'old run'], ['--run-tag=old run'], ['--last-run']):
                with self.subTest(viewer=flow, selection=selection):
                    args = [*selection, '--with-initial-state', 'runs/old run/state.json']
                    _, calls = self.launch(entry, *args)
                    self.assertEqual(calls[0]['args'], ['librelane', '--flow', flow, *args, './config.tcl'])

    def test_viewers_explain_missing_configuration(self):
        for entry in VIEWERS:
            with self.subTest(entry=entry):
                result, calls = self.launch(entry, expected=1)
                self.assertIn('Run 07_synthesize_for_asic.bash', result.stderr)
                self.assertEqual(calls, [])

    def test_viewer_failures_propagate(self):
        self.launch()
        self.env['TEST_EXIT'] = '23'
        for entry in VIEWERS:
            with self.subTest(entry=entry):
                _, calls = self.launch(entry, expected=23)
                self.assertEqual(len(calls), 1)

    @unittest.skipUnless(shutil.which('iverilog'), 'Icarus Verilog is not installed')
    def test_basic_staged_sources_elaborate_with_real_icarus(self):
        self.launch()
        stage = self.design / 'src'
        result = subprocess.run(['iverilog', '-g2012', '-s', 'asic_top', '-I', str(stage),
                                 '-o', str(self.base / 'probe.vvp'),
                                 *map(str, sorted(stage.glob('*.sv')))],
                                cwd=stage, text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)
