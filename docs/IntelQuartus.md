# Intel Quartus Prime

_"Intel Quartus Prime Lite Edition"_ is a free version of a software package
designed to manage boards based on _Cyclone_, _Arria_ and _MAX_ chipset families.
It is fully compatible with both [Windows](#Windows) and [Linux](#Linux).

> There is no documented way to run it on macOS, but you can try
using a virtual machine or Docker. No guarantees. If you do,
please share your experience.

## Windows

**Important:** According to Intel, you may need up to _30 GB_ of free space for the installation.

1. Download the
   [Intel® **Quartus**® Prime **Lite Edition** Design Software Version **23** for Windows](https://www.intel.com/content/www/us/en/products/details/fpga/development-tools/quartus-prime/resource.html)
   from Intel web site
   * _"Installer (New!)"_ is the recommended option as it speeds up the installation process.
     In case you need additional help with an installer tool,
     check out the _"Installer Quick Video"_ link from the same page
2. Running an intaller tool will prompt you to download and install the required packages:
   * Required: _"Quartus Prime Lite Edition"_, _"Device"_ support files for your board
   * Recommended: _"Quartus Prime Help"_, _"Questa-Intel"_, _"Quartus Prime Programmer and Tools"_
   * Default values for download and install paths are usually sufficient.
   * :warning: If one of device downloads fail (e.g. _"MAX 10"_,) skip it for now.
     Follow the [Troubleshooting](#Troubleshooting) instructions
     for a manual installation afterwards.
3. Verify you got up to three directories: `C:\flexlm`, `C:\intelFPGA`, and `C:\intelFPGA_lite`.

In most cases, no additional steps are necessary. The installation will be automatically detected and configured when an appropriate board is selected.

### Troubleshooting

#### Synthesis for a board fails with _Error (20004)_

You may encounter the following error message during synthesis:

> You can expect to get up to three directories: `C:\flexlm`, `C:\intelFPGA`, and `C:\intelFPGA_lite`.

In most cases, no additional steps are necessary. The installation will be automatically discovered and configured when an appropriate board is selected.


#### Synthesis for a board fails with _Error (20004)_

You may encounter the following error message during synthesis:

```
Info: *******************************************************************
Info: Running Quartus Prime Shell
Info: Command: quartus_sh --no_banner --flow compile fpga_project
Info: Quartus(args): compile fpga_project
Info: Project Name = C:/Users/user/Documents/basics-graphics-music/labs/1_basics/1_01_and_or_not_xor_de_morgan/run/fpga_project
Info: Revision Name = fpga_project
Info: *******************************************************************
Info: Running Quartus Prime Analysis & Synthesis
    Info: Version 23.1std.1 Build 993 05/14/2024 SC Lite Edition
    Info: Processing started: Sun Sep 15 03:35:49 2024
Info: Command: quartus_map --read_settings_files=on --write_settings_files=off fpga_project -c fpga_project

Error (20004): Your design targets the device family "MAX 10". The specified family is not a valid device family, is not installed, or is not supported in this version of the Quartus Prime software. If you restored a project from an archived version, your project was successfully restored, but you still must specify or install a supported device family.
```

This error indicates that the device files (e.g. _"MAX 10"_) were not installed
correctly. Follow the steps below to reinstall them manually:

1. Uninstall the device files if installed
   1. Open Window's Settings, and start an uninstaller for
      _"Quartus Prime Lite Edition"_
   1. Choose _"Individual components"_ and select a device file only (e.g. _"MAX 10 FPGA"_).
   1. Click _"Uninstall"_ to remove the files.
1. To install the device files see the instructions below

#### One of _Device_ files fails to download

You may need to install a device file (e.g. _"MAX 10 FPGA"_) manually.
Follow these steps:

1. Open an _Individual Files_ tab on the Quartus download page from above and download a device file
   (e.g. _"MAX® 10 FPGA device support"_) in a `*.qdz` format
1. Open _"Quartus (Quartus Prime) Lite Edition"_ and
   click menu _Tools > Install Devices..._.
   You may get a dialog box asking you to run
   _"Device Installer (Quartus Prime)"_ instead. Follow the instuction if
      prompted.
1. Point the installer to your `Downloads` folder and choose to select
   a device component to install (e.g. _"MAX 10 FPGA"_).
1. If you have run `06_choose_another_fpga_board.bash` already, you
   need to rerun it to pick the changes.


## Linux

_:wrench: TODO: Integrate with [beginner-s-guide-to-basics-graphics-music.md](./beginner-s-guide-to-basics-graphics-music.md)_
