"""Check DE25-Nano wiring and lab compatibility without Quartus or hardware.

Run: python3 scripts/tests/test_de25_nano.py
Requires Icarus Verilog (iverilog and vvp) on PATH. Simulations and compiler
outputs live in temporary directories; no FPGA image is produced.
"""

from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
BOARD = REPO / "boards/de25_nano"
FIXTURES = Path(__file__).resolve().parent / "fixtures/de25_nano"
IVERILOG = shutil.which("iverilog")
VVP = shutil.which("vvp")
BASIC_LABS = sorted((REPO / "labs/1_basics").glob("*/lab_top.sv"))
OTHER_LABS = (
    "4_microarchitecture/4_1_pipelines_1/4_1_1_pow5_single_cycle",
    "4_microarchitecture/4_2_fifo/4_2_1_start_with_shift_register",
    "4_microarchitecture/4_4_arbitration/4_4_1_round_robin_arbiter",
    "2_graphics/2_1_rectangle_ellipse_parabola",
)


class DE25NanoPinTests(unittest.TestCase):
    def test_onboard_io_matches_terasic_pin_tables(self):
        # Independently transcribed from the DE25-Nano manual rev. B:
        # Table 3-6 (clock), 3-8 (switches), 3-9 (keys), 3-10 (LEDs).
        # Voltage spelling and part number are from Terasic Golden Top.
        # https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1384&PartNo=4
        expected = {
            "CLOCK1_50": ("PIN_V16", "3.3-V LVCMOS"),
            "KEY[0]": ("PIN_C8", "3.3-V LVCMOS"),
            "KEY[1]": ("PIN_C11", "3.3-V LVCMOS"),
            "SW[0]": ("PIN_DK24", "1.1-V"),
            "SW[1]": ("PIN_DD24", "1.1-V"),
            "SW[2]": ("PIN_DD27", "1.1-V"),
            "SW[3]": ("PIN_DF27", "1.1-V"),
            "LEDR[0]": ("PIN_DF35", "1.1-V"),
            "LEDR[1]": ("PIN_DJ32", "1.1-V"),
            "LEDR[2]": ("PIN_DN22", "1.1-V"),
            "LEDR[3]": ("PIN_DP23", "1.1-V"),
            "LEDR[4]": ("PIN_DN25", "1.1-V"),
            "LEDR[5]": ("PIN_DP25", "1.1-V"),
            "LEDR[6]": ("PIN_DJ27", "1.1-V"),
            "LEDR[7]": ("PIN_DP30", "1.1-V"),
        }
        qsf = (BOARD / "board_specific.qsf").read_text()
        locations = re.findall(r"^set_location_assignment\s+(\S+)\s+-to\s+(\S+)",
                               qsf, re.MULTILINE)
        standards = dict((signal.strip('{}"'), voltage) for voltage, signal in re.findall(
            r'^set_instance_assignment\s+-name\s+IO_STANDARD\s+"([^"]+)"\s+-to\s+(\S+)',
            qsf, re.MULTILINE))
        by_signal = dict((signal.strip('{}"'), pin) for pin, signal in locations)
        self.assertEqual(len(locations), len(by_signal), "Duplicate pin assignments")
        self.assertEqual(len(locations), len({pin for pin, _ in locations}),
                         "Two ports cannot share a physical FPGA pin")
        for signal, (pin, voltage) in expected.items():
            with self.subTest(signal=signal):
                self.assertEqual(by_signal.get(signal), pin)
                bus = signal.split("[")[0] + "[*]"
                self.assertEqual(standards.get(signal, standards.get(bus)), voltage)
        self.assertRegex(qsf, r"(?m)^set_global_assignment\s+-name DEVICE A5EB013BB23BE4SCS\s*$")
        # The manual has a conflicting 3.3-V label for this clock output;
        # Golden Top assigns the actual bank voltage, 1.1 V.
        self.assertEqual(standards.get("HDMI_TX_CLK"), "1.1-V")


@unittest.skipUnless(IVERILOG and VVP, "Install iverilog and vvp to run RTL checks")
class DE25NanoRTLTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bgm-de25-nano-")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)

    def run_tool(self, command):
        result = subprocess.run(command, cwd=self.work, text=True,
                                capture_output=True, timeout=45)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def compile(self, lab, *, test=None, no_simulation=False, defines=()):
        lab = Path(lab)
        command = [IVERILOG, "-g2012", "-s", "tb" if test else "board_specific_top"]
        if test:
            command += [f"-DDE25_TEST_{test}", "-o", str(self.work / "simulation.vvp")]
            video = test in ("GRAPHICS", "GRAPHICS_FRAME", "GRAPHICS_I2C")
            if video:
                command += ["-DDE25_TEST_VIDEO"]
            # A local lab configuration selects the peripheral under test.
            (self.work / "lab_specific_board_config.svh").write_text(
                "`define INSTANTIATE_GRAPHICS_INTERFACE_MODULE\n"
                if video else "// No optional peripherals.\n"
            )
            command += ["-I", str(self.work)]
        else:
            command += ["-tnull"]
        if no_simulation:
            # Some teaching labs hide lab_top during their unit simulations.
            # This enables that RTL for elaboration only, without synthesis.
            command += ["-DNO_SIMULATION"]
        command += [f"-D{define}" for define in defines]
        for directory in (lab, BOARD, REPO / "labs/common", REPO / "peripherals"):
            command += ["-I", str(directory)]
        sources = []
        for directory in (BOARD, lab, REPO / "labs/common", REPO / "peripherals"):
            for extension in ("*.sv", "*.v"):
                sources += sorted(path for path in directory.glob(extension)
                                  if path.name != "tb.sv")
        if test:
            sources.append(FIXTURES / ("accessories_tb.sv" if test == "ACCESSORIES" else "tb.sv"))
        if test == "RESET_CONTRACT":
            sources.append(FIXTURES / "reset_release_stub.sv")
            command += ["-DINTEL_VERSION"]
        command += [str(path) for path in sources]
        return self.run_tool(command)

    def simulate(self, lab, test, *, defines=()):
        self.compile(lab, test=test, defines=defines)
        output = self.run_tool([VVP, str(self.work / "simulation.vvp")])
        self.assertIn(f"PASS: {test}", output)

    def test_mux_switch_selection_and_led_polarity(self):
        self.simulate(REPO / "labs/1_basics/1_02_mux", "MUX")

    def test_decoder_button_polarity(self):
        self.simulate(REPO / "labs/1_basics/1_03_decoder", "DECODER")

    def test_counter_clock_and_asynchronous_reset(self):
        self.simulate(REPO / "labs/1_basics/1_06_binary_counter", "COUNTER")

    def test_inactive_inputs_and_gpio_header_routing(self):
        self.simulate(FIXTURES / "probe", "PROBE")

    def test_hdmi_rgb_bus_and_line_timing(self):
        self.simulate(FIXTURES / "probe", "GRAPHICS")

    def test_hdmi_full_frame_and_vertical_blanking(self):
        self.simulate(FIXTURES / "probe", "GRAPHICS_FRAME")

    def test_hdmi_configuration_write_ack_and_retry(self):
        self.simulate(FIXTURES / "probe", "GRAPHICS_I2C")

    def test_startup_reset_release_contract(self):
        self.simulate(FIXTURES / "probe", "RESET_CONTRACT")

    def test_optional_accessories_elaborate_together(self):
        self.compile(REPO / "labs/1_basics/1_02_mux", defines=(
            "DE25_NANO_USE_TM1638", "DE25_NANO_USE_INMP441",
            "DE25_NANO_USE_I2S_AUDIO", "DE25_NANO_USE_UART",
        ))

    def test_optional_accessory_behavior_individually_and_together(self):
        accessories = ("TM1638", "INMP441", "I2S_AUDIO", "UART")
        configurations = [(), *((name,) for name in accessories), accessories]
        for configuration in configurations:
            with self.subTest(accessories=configuration or "all disabled"):
                self.simulate(FIXTURES / "accessories", "ACCESSORIES", defines=(
                    f"DE25_NANO_USE_{name}" for name in configuration
                ))

    def test_real_labs_elaborate_with_default_configuration(self):
        labs = [path.parent for path in BASIC_LABS]
        labs += [REPO / "labs" / path for path in OTHER_LABS]
        self.assertTrue(BASIC_LABS, "No basic labs found")
        for lab in labs:
            with self.subTest(lab=str(lab.relative_to(REPO))):
                self.compile(lab, no_simulation="4_2_fifo" in lab.parts)


if __name__ == "__main__":
    unittest.main(verbosity=2)
