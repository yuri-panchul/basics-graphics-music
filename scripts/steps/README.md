## How the setup script finds the location of the applicable toolchain:

Yuri Panchul
2023.09.14

A general note. We should not expect a typical user to mess with .bashrc or Windows environment variables. In most cases our script should be able to find the place where the toolchain installer put the toolchain by default.

### I. Intel FPGA / Altera

1. If quartus executable is in the path, the setup is considered done.

2. If FPGA < Cyclone IV, the install directory name (not full path) is "altera", otherwise it is "intelFPGA_lite".

3. If INTEL_FPGA_HOME is defined, it is used to search for "altera" or "intelFPGA_lite" inside.

4. If ALTERA_HOME is defined, it is used to search for "altera" or "intelFPGA_lite" inside.

5. If QUARTUS_HOME is defined, it is used to search for "altera" or "intelFPGA_lite" inside.

6. Linux: If INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME is not defined, we assume we need to search for altera|intelFPGA_lite inside $HOME. Note that the user can install Quartus into $HOME even without sudo/root priviledges.

7. Linux: If {INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME|HOME}/{altera|intelFPGA_lite} does not exist, we try to use "/opt" as a home dir. Note that the user has to use sudo/root priviledges in order to install Quartus into /opt.

8. Windows, Cygwin or MSys or MSys from Git: If INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME is not defined, we assume we need to search for altera|intelFPGA_lite inside "/c" (i.e. "C:\").

9. Windows, Cygwin or MSys or MSys from Git: If {INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME|C:\}/{altera|intelFPGA_lite} does not exist, we try to use "/d" (i.e. "D:\") as a home dir.

10. If the home dir (*/{altera|intelFPGA_lite}) has multiple versions (i.e. altera/13.0sp2 and altera/13.1, or intelFPGA_lite/21.1 and intelFPGA_lite/22.1), it uses the latest among them. Make a warning.

11. Linux: use "bin" subdirectory for the PATH to quartus.

12. Windows, Cygwin or MSys or MSys from Git: if FPGA < Cyclone IV, use "bin" subdirectory for the PATH to quartus, otherwise use "bin64" subdirectory.

13. Set QUARTUS_ROOTDIR (a variable used by Quartus) at {INTEL_FPGA_HOME|ALTERA_HOME|QUARTUS_HOME|HOME}/{altera|intelFPGA_lite}/<latest>/quartus.

## Gowin

1. Linux: If both gw_sh and openFPGALoader are in the path, consider setup done.

2. Windows, Cygwin or MSys or MSys from Git: If both gw_sh and programmer_cli are in the path, consider setup done.

3. Linux: If /opt/gowin exists, assume gw_sh and gw_ide are located at /opt/gowin/IDE/bin. Note that the user has to use sudo/root priviledges in order to install Gowin into /opt.

4. Linux: If $HOME/gowin exists, assume gw_sh and gw_ide are located at $HOME/gowin/IDE/bin. Note that the user can install Gowin into $HOME even without sudo/root priviledges.

TODO: Consider changing the priority order of /opt and $HOME.

5. Linux: If Gowin is not installed either in /opt/gowin or $HOME/gowin, error.

6. Windows, Cygwin or MSys or MSys from Git: if GOWIN_HOME is defined, assume and following and consider setup done:

    * $GOWIN_HOME/IDE/bin/gw_sh
    * $GOWIN_HOME/IDE/bin/gw_ide
    * $GOWIN_HOME/Programmer/bin/programmer_cli

TODO: GOWIN_HOME here has different meaning than ALTERA_HOME variable. It has the same meaning as XILINX_VIVADO variable.

7. Windows, Cygwin or MSys or MSys from Git: search the latest Gowin version in /c/Gowin. Then assume GOWIN_HOME=/c/Gowin/<latest>.

TODO: This is inconsistent with Linux, Altera and Xilinx. Need to review.

## Xilinx

1. If "vivado" executable is in the path, we consider the setup done.

2. If environment variable XILINX_HOME is defined, we assume $XILINX_HOME as the location for "Xilinx/Vivado" subdirectory that contains Vivado product.

3. Linux: If XILINX_HOME is not defined, and $HOME/Xilinx/Vivado exists, we use this location.

4. Linux: If {XILINX_HOME|HOME}/Xilinx/Vivado does not exist, we try to use "/opt" as a home dir. Note that the user has to use sudo/root priviledges in order to install Xilinx into /opt.

5. Linux: If {XILINX_HOME|HOME|/opt}/Xilinx/Vivado does not exist, we try to use "/tools" as a home dir. Note that the user has to use sudo/root priviledges in order to install Xilinx into /tools. Also note that /tools is the default location used by Xilinx Vivado installer.

6. Windows, Cygwin or MSys or MSys from Git: If XILINX_HOME is not defined, we try to use "/c", "/d", and "/e" (i.e. "C:\", "D:\" and "E:\") as the locations for the Xilinx/Vivado.

7. After determining the location of Xilinx/Vivado, we try to find the latest version in it. I.e. Xilinx/Vivado/2023.1.

8. When we find this version, we set XILINX_VIVADO, an environment variable used by Vivado, to this location.

TODO: Consider skipping the setup process if XILINX_VIVADO is already defined.
