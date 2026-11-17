"""Cmod A7-35T constraints, lab elaboration and functional wrapper simulation.

Run: python3 scripts/tests/test_cmod_a7_35.py
Icarus uses test-only MMCM/BUFG models. Real clock placement/timing requires Vivado.
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
BOARD = REPO / 'boards/cmod_a7_35'
FIX = Path(__file__).resolve().parent / 'fixtures/cmod_a7_35'


class CmodTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bgm-cmod-')
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)

    def run_command(self, args, timeout=120):
        r = subprocess.run(args, cwd=self.work, text=True, capture_output=True, timeout=timeout)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        return r.stdout + r.stderr

    def compile(self, lab, config=None, simulate=False, no_pll=False):
        board = REPO/'boards/cmod_a7_35_no_pll' if no_pll else BOARD
        if config is not None:
            (self.work / 'lab_specific_board_config.svh').write_text(config)
        output = self.work / 'test.vvp'
        args = ['iverilog', '-g2012', '-DNO_SIMULATION', '-s',
                'tb' if simulate else 'board_specific_top', '-o', str(output)]
        if no_pll:
            # No MMCM model is available: accidentally retaining one must fail elaboration.
            args += ['-DCMOD_TEST_NO_PLL']
        for directory in [self.work, lab, board, REPO/'labs/common', REPO/'peripherals']:
            args += ['-I', str(directory)]
        sources = [FIX/'clock_primitives.sv']
        for directory in [lab, board, REPO/'labs/common', REPO/'peripherals']:
            sources += [p for p in sorted(directory.glob('*.sv')) if p.name not in ('tb.sv', 'clock_primitives.sv')]
            sources += sorted(directory.glob('*.v'))
        filelist = lab/'filelist.f'
        if filelist.exists():
            sources += [lab/s.strip() for s in filelist.read_text().splitlines() if s.strip()]
        if simulate:
            sources.append(FIX/'tb.sv')
        self.run_command(args + list(map(str, sources)))
        return output

    def test_xdc_only_uncomments_original_definitions(self):
        original = (BOARD/'reference/Cmod-A7-Master.xdc').read_bytes()
        actual = (BOARD/'board_specific.xdc').read_bytes()
        manifest = json.loads((BOARD/'reference/source.json').read_text())
        self.assertEqual(hashlib.sha256(original).hexdigest(), manifest['sha256'])
        before, after = original.splitlines(keepends=True), actual.splitlines(keepends=True)
        self.assertEqual(len(before), len(after))
        for old, new in zip(before, after):
            self.assertTrue(new == old or (old.startswith(b'#') and new == old[1:]), new)
        pairs = re.findall(r'^set_property -dict \{ PACKAGE_PIN (\S+)\s+IOSTANDARD LVCMOS33 \} \[get_ports \{\s*(\S+)\s*\}\]', actual.decode(), re.M)
        self.assertEqual(len(pairs), 35)
        self.assertEqual(len(set(pin for pin, _ in pairs)), len(pairs))
        self.assertEqual({port for _, port in pairs}, set(manifest['enabled_ports']))
        # Independently selected connector positions: no accessory shares a pin.
        pins = {port: pin for pin, port in pairs}
        self.assertEqual([pins[f'pio{i}'] for i in range(26,35)],
                         ['R3','T3','R2','T1','T2','U1','W2','V2','W3'])
        self.assertEqual([pins[f'ja[{i}]'] for i in range(8)],
                         ['G17','G19','N18','L18','H17','H19','J19','K18'])
        self.assertEqual(actual, (REPO/'boards/cmod_a7_35_no_pll/board_specific.xdc').read_bytes())

    def test_top_ports_have_exact_xdc_coverage(self):
        netlist = self.compile(FIX, config='// All optional modules disabled.\n').read_text()
        section = netlist.split('.scope module, "board_specific_top"')[1].split('.scope ')[0]
        ports = re.findall(r'\.port_info \d+ /(INPUT|OUTPUT|INOUT) (\d+) "([^"]+)"', section)
        expanded = set()
        for _, width, name in ports:
            expanded.update([name] if width == '1' else [f'{name}[{i}]' for i in range(int(width))])
        manifest = json.loads((BOARD/'reference/source.json').read_text())
        self.assertEqual(expanded, set(manifest['enabled_ports']))

    def test_representative_labs_elaborate(self):
        labs = sorted((REPO/'labs/1_basics').glob('*/lab_top.sv'))
        labs += [REPO/'labs'/name/'lab_top.sv' for name in [
            '2_graphics/2_1_rectangle_ellipse_parabola',
            '2_graphics/2_4_game',
            '3_music/3_0_oscilloscope',
            '3_music/3_3_note_synthesizer',
            '3_music/3_11_microphone_monitor',
            '4_microarchitecture/4_1_pipelines_1/4_1_1_pow5_single_cycle',
            '4_microarchitecture/4_2_fifo/4_2_1_start_with_shift_register']]
        for no_pll in (False, True):
            for lab in labs:
                with self.subTest(lab=str(lab.relative_to(REPO)), no_pll=no_pll):
                    self.compile(lab.parent, no_pll=no_pll)

    def test_tm_options_elaborate(self):
        for no_pll in (False, True):
            for option in ['', 'CONCAT_TM1638_SIGNALS_AND_REGULAR',
                           'CONCAT_REGULAR_SIGNALS_AND_TM1638',
                           'SPLIT_TM1638_DIO_INOUT_SIGNAL',
                           'USE_HCW132_VARIANT_OF_TM1638_BOARD_CONTROLLER_MODULE']:
                with self.subTest(option=option, no_pll=no_pll):
                    self.compile(FIX, config='`define INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE\n'
                                 + (f'`define {option}\n' if option else ''), no_pll=no_pll)

    def test_frame_audio_microphone_and_reset(self):
        self.check_frame(no_pll=False)

    def test_no_pll_frame_audio_microphone_and_reset(self):
        self.check_frame(no_pll=True)

    def check_frame(self, no_pll):
        config = ''.join(f'`define INSTANTIATE_{s}_MODULE\n' for s in [
            'GRAPHICS_INTERFACE', 'MICROPHONE_INTERFACE', 'SOUND_OUTPUT_INTERFACE',
            'TM1638_BOARD_CONTROLLER'])
        output = self.compile(FIX, config=config, simulate=True, no_pll=no_pll)
        result = self.run_command(['vvp', str(output)])
        self.assertIn('PASS:', result)
        print(result.strip())


if __name__ == '__main__':
    unittest.main(verbosity=2)
