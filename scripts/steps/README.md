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

1. If `XILINX_VIVADO` names a directory containing `bin`, append that `bin` directory to `PATH` and consider setup done. Otherwise, if `vivado` is already in `PATH`, consider setup done.

2. If `XILINX_HOME` is defined, search that parent directory first.

3. On Linux, search `$HOME`, `/opt`, and `/tools`, in that order, after the explicit parent. On Cygwin/MSYS, search `/c`, `/d`, and `/e` instead. These paths correspond to Windows drives `C:\`, `D:\`, and `E:\`, respectively.

4. Under each parent, recognize `<parent>/<vendor>/Vivado/<version>` and `<parent>/<vendor>/<version>/Vivado`, where `<vendor>` can be `Xilinx`, `AMD`, or `AMDDesignTools`. A version-directory name must begin with a digit, and an installation must contain a `bin` directory. Symlinked version directories are supported; names such as `backup` are ignored.

5. Use the first parent containing an installation. Within that parent, select the newest version across all supported vendors and layouts using version-aware sorting (`sort -V`), so `2026.10` sorts after `2026.2`. Equal versions are ordered by installation path in the C locale; the alphabetically last path wins. There is no vendor preference.

   Discovery tries `/usr/bin/sort`, `/bin/sort`, then `sort` from `PATH`, checking version-sorting support before use. This avoids Windows' native `sort.exe`. If no compatible Unix utility is available, it warns and uses `sort` from `PATH` without options as a Windows fallback. The fallback utility controls alphabetical ordering and equal-version ties, which may differ from Unix sort. This ordering may select an older version; set `XILINX_VIVADO` to override it. Sorting failures still report an error.

For example, `/home/verilog/AMD/2026.1/Vivado` is discovered when `$HOME` is `/home/verilog`. To select it explicitly, set `XILINX_VIVADO=/home/verilog/AMD/2026.1/Vivado`; to search its parent, set `XILINX_HOME=/home/verilog`.

## LibreLane

The ASIC scripts (`07_synthesize_for_asic.bash`, `08_visualize_asic_synthesis_results_1.bash` and `09_visualize_asic_synthesis_results_2.bash`) look for LibreLane only. Other scripts skip this step. See [docs/LibreLane.md](../../docs/LibreLane.md) for the installation.

1. The viewers 08 and 09 first check that 07 has made results for the lab. Without them, they stop and say to run 07 first, before anything below.

2. If `LIBRELANE_PATH` is defined, prepend it to `PATH`.

3. If `librelane` is in `PATH`, consider setup done. This is the case inside a Nix shell or inside an interactive shell of the LibreLane AppImage.

4. In Git Bash or Cygwin on Windows, run the same lab script again in WSL2 and exit with its status: `wsl.exe --cd <lab directory> -e bash ./<script>`. Before that, check that WSL2 is installed, that it is not WSL 1, and that the scripts do not have Windows line endings, and say how to fix each.

5. On macOS, stop and print the Nix installation steps of the LibreLane guide. macOS has no AppImage.

6. Otherwise, look for the LibreLane AppImage. If `LIBRELANE_APPIMAGE` is defined, use that file. Otherwise, use the newest `librelane*<machine>*.AppImage` in `$HOME` or in `$HOME/Downloads`, where `<machine>` is the output of `uname -m`, for example `librelane-devshell-x86_64.AppImage`.

7. If there is no AppImage, offer to download the AppImage of `librelane_version` (3.0.17) from the LibreLane releases into `$HOME`. Before asking, check that `$HOME` has 4 GB free. The download goes to a `.part` file, which a later run continues if the download stops. Then check the file's size and SHA-256 sum, rename it and make it executable.

8. If the file is not executable, make it executable.

9. Start the AppImage with the command `true`. If it works, the scripts run `<AppImage> librelane <arguments>`: the AppImage runs the command inside its environment and exits with its status. The user does not need to start the AppImage first.

10. If the AppImage cannot start, usually with "cannot unshare" because the system disables unprivileged user namespaces, and `bwrap` works, the scripts run LibreLane under `bwrap`. They mount the AppImage with `--appimage-mount`, run its entrypoint under `bwrap` with the AppImage's `/nix` in place and every other top-level directory of the system bound as is, and unmount the AppImage afterwards. ALT Linux disables unprivileged user namespaces by default and installs `bwrap` setuid root, so this works there without root.

11. Otherwise, find the reason and stop with the commands that fix it: installing FUSE, the AppArmor setting of Ubuntu 24.04 and newer, `kernel.unprivileged_userns_clone` or `user.max_user_namespaces`. The scripts do not run these commands, since they need root.

The results go to `librelane_designs/<lab>` in the root of the package: `07_synthesize_for_asic.bash` copies the sources there and runs `librelane --flow Classic config.tcl`, and the viewers open the last run with the `OpenInOpenROAD` and `OpenInKLayout` flows.
