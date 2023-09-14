## How the setup script finds the location of the applicable toolchain:

Yuri Panchul
2023.09.14

### Intel FPGA / Altera

1. If quartus executable is in the path, the setup is considered done.

2. If FPGA < Cyclone IV, the install directory name (not full path) is "altera", otherwise it is "intelFPGA_lite".

3. If INTEL_FPGA_HOME is defined, it is used to put "altera" or "intelFPGA_lite" inside.

4. If ALTERA_HOME is defined, it is used to put "altera" or "intelFPGA_lite" inside.

5. If QUARTUS_HOME is defined, it is used to put "altera" or "intelFPGA_lite" inside.

6. Linux: If INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME is not defined, we assume we need to put altera|intelFPGA_lite inside $HOME.

7. Linux: If {INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME|HOME}/{altera|intelFPGA_lite} does not exist, we try to use "/opt" as a home dir.

8. Windows, Cygwin or MSys or MSys from Git: If INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME is not defined, we assume we need to put altera|intelFPGA_lite inside "/c" (i.e. "C:\").

9. Windows, Cygwin or MSys or MSys from Git: If {INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME|C:\}/{altera|intelFPGA_lite} does not exist, we try to use "/d" (i.e. "D:\") as a home dir.

10. If the home dir (*/{altera|intelFPGA_lite}) has multiple versions (i.e. altera/13.0sp2 and altera/13.1, or intelFPGA_lite/21.1 and intelFPGA_lite/22.1), it uses the latest among them. Make a warning.

11. Linux: use "bin" subdirectory for the PATH to quartus.

12. Windows, Cygwin or MSys or MSys from Git: if FPGA < Cyclone IV, use "bin" subdirectory for the PATH to quartus, otherwise use "bin64" subdirectory.

13. Set QUARTUS_ROOTDIR (a variable used by Quartus) at {INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME|HOME}/{altera|intelFPGA_lite}/<latest>/quartus.

## Gowin

