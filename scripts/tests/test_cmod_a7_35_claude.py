"""Check the six Cmod A7 configurations of Claude without hardware.

Run: python3 scripts/tests/test_cmod_a7_35_claude.py

The configurations are boards/cmod_a7_35_tiny_vga_640_claude, which holds the
top level, and the five that include it: without the MMCM (_no_pll_..._304,
_no_pll_..._320) and without TM1638 (_no_tm1638). The tests check:

* that every board_specific.xdc is Digilent's Cmod-A7-Master.xdc with only
  some lines uncommented, and that its ports are exactly the top level ports;
* that a set of labs elaborates with every configuration, among them the labs
  fixed for a board with two keys, two LEDs and one digit, and that a lab
  elaborates with TM1638, VGA, the microphone and the DAC all turned off;
* that the SPLIT_TM1638_DIO_INOUT_SIGNAL option stops the build with an error;
* the pins of every configuration in simulation, with the self-checking
  fixtures/cmod_a7_35_claude/tb.sv: clock and reset, VGA timing, colors,
  microphone, DAC, buttons, LEDs, RGB LED, GPIO, UART and TM1638 pins.

Requires Icarus Verilog (iverilog and vvp) on PATH; it takes about a minute.
With BGM_TEST_VIVADO=1 it also builds a lab for each configuration with
Vivado, one configuration at a time, through build_cmod_a7_35_claude.tcl:
about three minutes each. Vivado is $XILINX_VIVADO/bin/vivado or vivado on PATH.
All outputs go to temporary directories.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib
import os
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
BOARDS = REPO / "boards"
FIXTURES = Path(__file__).resolve().parent / "fixtures/cmod_a7_35_claude"
IVERILOG = shutil.which("iverilog")
VVP = shutil.which("vvp")
JOBS = max(1, min(4, os.cpu_count() or 1))

MAIN = "cmod_a7_35_tiny_vga_640_claude"

# Configuration: (screen width, with TM1638)

CONFIGS = {
    "cmod_a7_35_tiny_vga_640_claude":                  (640, True),
    "cmod_a7_35_tiny_vga_640_no_tm1638_claude":        (640, False),
    "cmod_a7_35_no_pll_tiny_vga_304_claude":           (304, True),
    "cmod_a7_35_no_pll_tiny_vga_304_no_tm1638_claude": (304, False),
    "cmod_a7_35_no_pll_tiny_vga_320_claude":           (320, True),
    "cmod_a7_35_no_pll_tiny_vga_320_no_tm1638_claude": (320, False),
}

# Digilent's file, unchanged, from
# https://github.com/Digilent/digilent-xdc/blob/c8644a9fe31cc803789643124545d56b3bef4600/Cmod-A7-Master.xdc

DIGILENT_XDC = FIXTURES / "Cmod-A7-Master.xdc"
DIGILENT_XDC_SHA256 = "56568df3868ef359e938ef8defab33e1814fe4153435e99e13da9260d9db4eaf"

USED_PORTS = (
    {"sysclk", "led0_b", "led0_g", "led0_r", "uart_txd_in", "uart_rxd_out"}
    | {f"btn[{i}]" for i in range(2)}
    | {f"led[{i}]" for i in range(2)}
    | {f"ja[{i}]" for i in range(8)}
    | {f"pio{i}" for i in [*range(1, 9), 21, 22, 23, 26, 27, 28, 29, 30, 31, 32]}
)

LABS = sorted(p.parent for p in (REPO / "labs/1_basics").glob("*/lab_top.sv")) + [
    REPO / "labs" / lab
    for lab in (
        "2_graphics/2_1_rectangle_ellipse_parabola",
        "2_graphics/2_4_game",
        "3_music/3_3_note_synthesizer",
        "3_music/3_11_microphone_monitor",
        "4_microarchitecture/4_1_pipelines_1/4_1_3_pow5_pipelined_valid",
        "4_microarchitecture/4_1_pipelines_1/4_1_4_pow5_pipelined_valid_solution",
        "4_microarchitecture/4_2_fifo/4_2_1_start_with_shift_register",
        "4_microarchitecture/4_2_fifo/4_2_2_ring_buffer_with_single_pointer_saves_power_view_1_functional",
        "4_microarchitecture/4_2_fifo/4_2_3_ring_buffer_with_single_pointer_view_2_data_layout",
        "4_microarchitecture/4_2_fifo/4_2_5_optimized_ff_fifo_view_2_data_layout",
        "6_misc/6_1_geiger_muller_radiation_counter_claude",
    )
]

ALL_INTERFACES = "".join(
    f"`define INSTANTIATE_{name}_MODULE\n"
    for name in ("TM1638_BOARD_CONTROLLER", "GRAPHICS_INTERFACE",
                 "MICROPHONE_INTERFACE", "SOUND_OUTPUT_INTERFACE")
)

VIVADO_LAB = "labs/3_music/3_11_microphone_monitor"


def lab_sources(lab):
    """The sources of a lab, as scripts/fpga/xilinx_vivado_synthesize.tcl reads them."""

    if lab == FIXTURES:
        return [FIXTURES / "lab_top.sv"]

    sources = [p for p in sorted(lab.glob("*.sv")) + sorted(lab.glob("*.v")) if p.name != "tb.sv"]
    filelist = lab / "filelist.f"

    if filelist.exists():
        sources += [lab / line.strip() for line in filelist.read_text().splitlines() if line.strip()]

    return sources


def compile_design(work, config, lab, board_config=None, defines=(), testbench=False):
    """Compile a configuration with a lab using Icarus; return (ok, output, vvp file).

    board_config, when given, is written as lab_specific_board_config.svh in
    the work directory, which comes first on the include path.
    """

    work.mkdir(parents=True, exist_ok=True)
    board = BOARDS / config
    out = work / "design.vvp"

    if board_config is not None:
        (work / "lab_specific_board_config.svh").write_text(board_config)

    args = [IVERILOG, "-g2012", "-DNO_SIMULATION", "-o", str(out),
            "-s", "tb" if testbench else "board_specific_top"]
    args += [f"-D{d}" for d in defines]

    for directory in (work, lab, board, REPO / "labs/common", REPO / "peripherals"):
        args += ["-I", str(directory)]

    sources = [FIXTURES / "clock_primitives.sv", *lab_sources(lab), board / "board_specific_top.sv"]
    sources += sorted((REPO / "labs/common").glob("*.sv"))
    sources += sorted((REPO / "peripherals").glob("*.sv")) + sorted((REPO / "peripherals").glob("*.v"))

    if testbench:
        sources.append(FIXTURES / "tb.sv")

    r = subprocess.run(args + [str(s) for s in sources], cwd=work, text=True,
                       capture_output=True, timeout=300)

    return r.returncode == 0 and out.exists(), r.stdout + r.stderr, out


def xdc_ports(path):
    return set(re.findall(r"^set_property .*\[get_ports \{\s*(\S+)\s*\}\]", path.read_text(), re.M))


@unittest.skipUnless(IVERILOG and VVP, "Icarus Verilog (iverilog, vvp) is not on PATH")
class CmodA7ClaudeTests(unittest.TestCase):

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bgm-cmod-a7-claude-")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)

    #------------------------------------------------------------------------

    def test_configurations_are_the_ones_on_disk(self):
        on_disk = {p.name for p in BOARDS.glob("cmod_a7_35*_claude*") if p.is_dir()}
        self.assertEqual(on_disk, set(CONFIGS))

        for config in CONFIGS:
            tcl = (BOARDS / config / "board_specific.tcl").read_text()
            self.assertIn(f"set fpga_board  {config}\n", tcl)
            self.assertIn("set part_name   xc7a35tcpg236-1\n", tcl)

            if config != MAIN:
                top = (BOARDS / config / "board_specific_top.sv").read_text()
                self.assertIn(f'`include "../{MAIN}/board_specific_top.sv"', top)
                self.assertLess(len(top.splitlines()), 12, "only the main top level holds the design")

    def test_digilent_xdc_is_unchanged(self):
        self.assertEqual(hashlib.sha256(DIGILENT_XDC.read_bytes()).hexdigest(), DIGILENT_XDC_SHA256)

    def test_xdc_only_uncomments_digilent_lines(self):
        original = DIGILENT_XDC.read_bytes().splitlines(keepends=True)
        main = (BOARDS / MAIN / "board_specific.xdc").read_bytes()

        for config in CONFIGS:
            with self.subTest(config=config):
                xdc = (BOARDS / config / "board_specific.xdc").read_bytes()
                self.assertEqual(xdc, main, "all six configurations share one XDC")
                lines = xdc.splitlines(keepends=True)
                self.assertEqual(len(lines), len(original))

                for old, new in zip(original, lines):
                    self.assertTrue(new == old or (old.startswith(b"#") and new == old[1:]),
                                    f"changed line: {new!r}")

        self.assertEqual(xdc_ports(BOARDS / MAIN / "board_specific.xdc"), USED_PORTS)
        self.assertRegex(main.decode(), r"(?m)^create_clock .*\[get_ports \{\s*sysclk\s*\}\]")

    def test_top_level_ports_are_the_xdc_ports(self):
        for config in CONFIGS:
            with self.subTest(config=config):
                ok, log, out = compile_design(self.work / config, config, FIXTURES, ALL_INTERFACES)
                self.assertTrue(ok, log)
                scope = out.read_text().split('.scope module, "board_specific_top"')[1].split(".scope ")[0]
                ports = set()

                for width, name in re.findall(r'\.port_info \d+ /(?:INPUT|OUTPUT|INOUT) (\d+) "([^"]+)"', scope):
                    ports |= {name} if width == "1" else {f"{name}[{i}]" for i in range(int(width))}

                self.assertEqual(ports, xdc_ports(BOARDS / config / "board_specific.xdc"))

    #------------------------------------------------------------------------

    def test_labs_elaborate(self):
        jobs = [(config, lab) for config in CONFIGS for lab in LABS]

        def run(job):
            config, lab = job
            work = self.work / config / lab.name
            return compile_design(work, config, lab)[:2]

        with ThreadPoolExecutor(JOBS) as pool:
            results = list(pool.map(run, jobs))

        for (config, lab), (ok, log) in zip(jobs, results):
            with self.subTest(config=config, lab=str(lab.relative_to(REPO))):
                self.assertTrue(ok, log)

    def test_lab_without_interfaces_elaborates(self):
        lab = REPO / "labs/1_basics/1_01_and_or_not_xor_de_morgan"

        for config in CONFIGS:
            with self.subTest(config=config):
                ok, log, _ = compile_design(self.work / config, config, lab, "")
                self.assertTrue(ok, log)

    def test_split_tm1638_dio_is_rejected(self):
        option = ALL_INTERFACES + "`define SPLIT_TM1638_DIO_INOUT_SIGNAL\n"

        for config, (_, with_tm1638) in CONFIGS.items():
            with self.subTest(config=config):
                ok, log, _ = compile_design(self.work / config, config, FIXTURES, option)

                if with_tm1638:
                    self.assertFalse(ok)
                    self.assertIn("SPLIT_TM1638_DIO_INOUT_SIGNAL is not supported on Cmod A7", log)
                else:
                    self.assertTrue(ok, log)

    #------------------------------------------------------------------------

    def test_pins_in_simulation(self):
        def run(config):
            width, with_tm1638 = CONFIGS[config]
            defines = [f"CMOD_TEST_SCREEN_WIDTH={width}"] + ([] if with_tm1638 else ["CMOD_TEST_NO_TM1638"])
            work = self.work / config
            ok, log, out = compile_design(work, config, FIXTURES, ALL_INTERFACES, defines, testbench=True)

            if not ok:
                return False, log

            r = subprocess.run([VVP, "-n", str(out)], cwd=work, text=True, capture_output=True, timeout=600)
            return r.returncode == 0 and "PASS:" in r.stdout, r.stdout + r.stderr

        with ThreadPoolExecutor(JOBS) as pool:
            results = dict(zip(CONFIGS, pool.map(run, CONFIGS)))

        for config, (ok, log) in results.items():
            with self.subTest(config=config):
                self.assertTrue(ok, log)
                print(f"{config}: {log.strip().splitlines()[-2]}")

    #------------------------------------------------------------------------

    @unittest.skipUnless(os.environ.get("BGM_TEST_VIVADO") == "1", "set BGM_TEST_VIVADO=1 to build with Vivado")
    def test_vivado_builds(self):
        vivado = shutil.which("vivado")

        if os.environ.get("XILINX_VIVADO"):
            vivado = str(Path(os.environ["XILINX_VIVADO"]) / "bin/vivado")

        # BGM_TEST_VIVADO=1 asks for Vivado, so a missing Vivado is a failure

        if not vivado or not Path(vivado).exists():
            self.fail("BGM_TEST_VIVADO=1, but Vivado is not found: set XILINX_VIVADO or put vivado on PATH")

        script = Path(__file__).resolve().parent / "build_cmod_a7_35_claude.tcl"

        # One configuration at a time: Vivado takes a few GB of memory

        for config in CONFIGS:
            with self.subTest(config=config):
                work = self.work / ("vivado_" + config)
                work.mkdir()
                r = subprocess.run([vivado, "-mode", "batch", "-nojournal", "-nolog",
                                    "-source", str(script), "-tclargs", VIVADO_LAB, config],
                                   cwd=work, text=True, capture_output=True, timeout=1800)
                log = r.stdout + r.stderr
                result = [line for line in log.splitlines() if line.startswith("CMOD_A7_CLAUDE_BUILD_OK")]
                self.assertTrue(r.returncode == 0 and result, log[-5000:])
                print(result[0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
