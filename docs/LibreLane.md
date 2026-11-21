# ASIC synthesis with LibreLane

[LibreLane](https://github.com/librelane/librelane) is an open-source RTL-to-GDSII flow: it turns
the Verilog of a lab into the layout of a chip for an open PDK, the SkyWater 130 nm process by
default. It is the successor of OpenLane. Each lab directory has three scripts for it:

| Script | What it does |
|---|---|
| `07_synthesize_for_asic.bash` | Copies the lab into `librelane_designs/<lab>` in the root of the package and runs the whole flow: synthesis, floorplan, placement, clock tree, routing, timing, DRC and LVS. |
| `08_visualize_asic_synthesis_results_1.bash` | Opens the last run in the OpenROAD GUI. |
| `09_visualize_asic_synthesis_results_2.bash` | Opens the last run in KLayout. |

**On Linux, the scripts install and start LibreLane themselves.** The first run offers to
download the LibreLane AppImage, a single file with LibreLane and all its tools. After that,
the scripts start it for every run; you do not need to open an AppImage shell first.
On Windows, the scripts do the same inside WSL2. On macOS, you install LibreLane with Nix once.

## Requirements

* One of:
  * Linux on x86-64 or ARM64;
  * Windows 10 version 2004 or newer, or Windows 11, with WSL2 (see [On Windows](#on-windows));
  * macOS 15 or newer with Nix (see [On macOS](#on-macos)).
* 8 GB of memory and 4 processor cores, which LibreLane's documentation gives as the minimum.
* FUSE on Linux, as for any AppImage: the `fuse3` or `fuse` package, which most desktop Linux
  systems already have. If it is missing, the scripts say how to install it.
* Disk space, measured with LibreLane 3.0.17:

  | What | Download | On disk |
  |---|---|---|
  | The AppImage, in your home directory | 1.4 GB | 1.4 GB |
  | The SkyWater 130 nm PDK in `~/.ciel`, downloaded by the first run | 0.34 GB | 2.2 GB |
  | One run of `1_06_binary_counter` | | about 1 GB |

  A run is large because every lab gets a 1 mm × 1 mm die, and the filler cells of the empty
  area take most of the space.

## On Linux

1. Run the ASIC synthesis of a small lab:

   ```bash
   cd labs/1_basics/1_06_binary_counter
   ./07_synthesize_for_asic.bash
   ```

   The first time, the script says that LibreLane is not installed and asks
   `Download LibreLane now? [Y/n]`. Press Enter. The script downloads the LibreLane 3.0.17
   AppImage into your home directory, checks its SHA-256 sum and continues. If the download
   stops, run the script again: it continues the download from where it stopped.

   Then LibreLane downloads the PDK into `~/.ciel`. Later runs use both. For
   `1_06_binary_counter`, the whole flow takes about 20 minutes on a 4-core computer. Most of
   that time goes to the design rule checks of the 1 mm × 1 mm die in Magic and KLayout. At
   the end, the flow reports the checks it ran: no DRC, LVS or antenna errors and no timing
   violations.

2. Look at the result:

   ```bash
   ./08_visualize_asic_synthesis_results_1.bash   # OpenROAD GUI
   ./09_visualize_asic_synthesis_results_2.bash   # KLayout
   ```

   The viewers need a graphical desktop. Over `ssh`, connect with `ssh -X`.

To download the AppImage yourself instead, put `librelane-devshell-x86_64.AppImage` (or
`librelane-devshell-aarch64.AppImage` on ARM) from the
[LibreLane releases](https://github.com/librelane/librelane/releases) into your home directory
or into `~/Downloads`:

```bash
cd ~
curl -L -O https://github.com/librelane/librelane/releases/download/3.0.17/librelane-devshell-x86_64.AppImage
chmod a+x librelane-devshell-x86_64.AppImage
```

The SHA-256 sum of the 3.0.17 file is
`c8ef5ae26b1fc53dd1dd30fe2f1a1da6ab0fdf471dd5a94c2b85d2b3db36833c` for x86-64 and
`902311ed81828b8b5c64a8759b718c1df62f64c2936bee7e6c800b99c25a5b34` for ARM64.

## On Windows

LibreLane runs on Linux. On Windows, it runs in WSL2, the Linux inside Windows.

1. Install WSL2 once:
   1. Open PowerShell as Administrator and run `wsl --install -d Ubuntu`.
   2. Restart Windows.
   3. Open Ubuntu from the Start menu and choose a user name and a password.

2. Run `07_synthesize_for_asic.bash` in Git Bash as usual. The script says
   `LibreLane runs on Linux, so "07_synthesize_for_asic.bash" continues in WSL2` and runs
   itself again in Ubuntu. From there, everything goes as [on Linux](#on-linux): the first
   time, the script offers to download LibreLane into the home directory of Ubuntu.

Notes:

* The results go to the same `librelane_designs` directory of the repository, so you can find
  them in Windows too.
* The viewers 08 and 09 need the graphics of WSL, which Windows 11 has. On Windows 10, run
  `wsl --update` in PowerShell to get them.
* Linux reads and writes the files on drive C: more slowly than its own files. For faster
  runs, clone the repository inside Ubuntu and run the scripts in the Ubuntu terminal.
* The scripts need Unix line endings. Git for Windows changes them to Windows ones when its
  `core.autocrlf` setting is `true`, and then the script says so. To get a copy that works,
  clone the repository again with
  `git clone --config core.autocrlf=input https://github.com/yuri-panchul/basics-graphics-music.git`.

## On macOS

macOS has no AppImage. Install LibreLane with Nix, as the
[LibreLane installation guide](https://librelane.readthedocs.io/en/latest/installation/nix_installation/installation_macos.html)
describes. The script prints these steps when it does not find LibreLane:

1. Install Nix. It asks for your password and takes about 5 minutes:

   ```bash
   curl --proto '=https' --tlsv1.2 -fsSL https://artifacts.nixos.org/nix-installer | sh -s -- install --no-confirm --extra-conf "
       extra-substituters = https://nix-cache.fossi-foundation.org
       extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
       extra-experimental-features = nix-command flakes
   "
   ```

2. Close all terminals, open a new one and get LibreLane:

   ```bash
   git clone --branch 3.0.17 https://github.com/librelane/librelane ~/librelane
   ```

3. Each time, start the LibreLane shell first, then run the scripts in it. The first time takes
   about 10 minutes:

   ```bash
   cd ~/librelane && nix-shell
   ```

LibreLane's first version in 2027 drops Intel Macs, because Nix stops supporting them. On an
Intel Mac, use a Linux virtual machine, for example [lima](https://lima-vm.io), and the Linux
steps.

## Where the results are

Each run of `07_synthesize_for_asic.bash` makes a new directory
`librelane_designs/<lab>/runs/RUN_<date>_<time>`:

* `final/` has the results: `gds/` (the layout), `nl/` and `pnl/` (the netlists, without and with
  power pins), `sdf/`, `spef/`, `lib/`, and `metrics.csv` and `metrics.json` with area, cell
  counts, timing, power and the DRC and LVS checks.
* One numbered directory per step, with its logs and reports. For example,
  `06-yosys-synthesis` has the synthesized netlist, `55-openroad-stapostpnr/summary.rpt` the
  timing after routing, and `59-klayout-render/asic_top.png` a picture of the layout.
  The numbers can change between LibreLane versions.
* `flow.log` has the messages of the whole run; `warning.log` and `error.log` have the warnings
  and the errors.

Old runs are not deleted. Delete the `runs` directories you no longer need, or the whole
`librelane_designs` directory.

## If the AppImage cannot start

The AppImage needs FUSE and unprivileged user namespaces. When it cannot start, the scripts
find the reason and print the commands that fix it. They do not run these commands
themselves, because the commands need root:

* **FUSE is not installed:** the script prints the command that installs `fuse3`, for example
  `sudo apt-get install -y fuse3`.

* **Ubuntu 24.04 and newer, and the systems based on them, such as Lubuntu, Kubuntu, Xubuntu
  and Linux Mint 22,** restrict the namespaces with AppArmor. LibreLane's guide gives these
  commands:

  ```bash
  sudo apt-get install -y uidmap
  echo "kernel.apparmor_restrict_unprivileged_userns = 0" | sudo tee /etc/sysctl.d/99-userns.conf && sudo sysctl --system
  ```

* **ALT Linux** disables the namespaces, so the AppImage stops with
  `cannot unshare: Operation not permitted`. ALT Linux installs `bwrap` setuid root, so the
  scripts run the AppImage under `bwrap` instead and print
  "Unprivileged user namespaces are disabled, so the LibreLane AppImage runs under bwrap".
  Nothing needs to be changed. To start the AppImage by hand as well, enable the namespaces:

  ```bash
  echo "kernel.unprivileged_userns_clone = 1" | sudo tee /etc/sysctl.d/99-userns.conf && sudo sysctl --system
  ```

  Some Debian setups disable the namespaces the same way, and the script prints the same
  command there.

If LibreLane prints `warning: setlocale: cannot change locale (en_US.UTF-8)`, see
[LibreLane's note on it](https://librelane.readthedocs.io/en/latest/installation/appimage_installation/index.html).
Often `export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive` before the script is enough.

## How the scripts find LibreLane

1. If `LIBRELANE_PATH` is set, it is added to `PATH`.
2. If `librelane` is in `PATH`, the scripts run it directly. This is the case inside a Nix shell,
   or inside the AppImage's own shell, which opens when you run the AppImage without arguments.
3. In Git Bash on Windows, the scripts run themselves again in WSL2. On macOS, they print the
   Nix steps.
4. Otherwise, the scripts use the AppImage named by `LIBRELANE_APPIMAGE`, or the newest
   `librelane*<machine>*.AppImage` in your home directory or in `~/Downloads`. If there is
   none, they offer to download it. They run `<AppImage> librelane <arguments>`, or the same
   under `bwrap` when the AppImage cannot start by itself.

To use an AppImage kept elsewhere:

```bash
export LIBRELANE_APPIMAGE=/opt/librelane/librelane-devshell-x86_64.AppImage
```

The details are in [scripts/steps/README.md](../scripts/steps/README.md#librelane).

## The AppImage shell

Run the AppImage without arguments to get a shell with `librelane`, `yosys`, `openroad`,
`klayout`, `magic`, `netgen` and `verilator` in `PATH`:

```bash
~/librelane-devshell-x86_64.AppImage
```

The scripts also work inside this shell. With LibreLane's own example:

```bash
librelane --smoke-test
```

## Preparing computers for a class

The first run needs the Internet to download the AppImage and the PDK. To prepare computers
that will be offline, run one lab once on each computer, or copy the AppImage and the `~/.ciel`
directory from a computer where a run has worked.

## Other installations

LibreLane's [installation guide](https://librelane.readthedocs.io/en/latest/installation/index.html)
also describes Nix, the best option for regular use, and Docker. Any installation that puts the
`librelane` command in `PATH` works with the scripts.

## Known limitations

* `asic_top.sv` in `scripts/asic` connects the clock, reset, keys, switches, LEDs and the
  seven-segment display. The graphics, sound, microphone, UART and GPIO ports of `lab_top` are
  not connected, so the logic that only drives them is removed and such labs produce an almost
  empty chip.
* Labs that hide `lab_top` under `` `ifndef SIMULATION `` fail LibreLane's first step,
  Verilator lint, because `labs/common/config.svh` treats Verilator as a simulator.
* Every lab gets a die of 1 mm × 1 mm (0.5 mm × 0.5 mm for the CPU labs with their own
  `asic_config.tcl`).
