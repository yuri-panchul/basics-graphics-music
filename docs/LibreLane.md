# ASIC synthesis with LibreLane

[LibreLane](https://github.com/librelane/librelane) is an open-source RTL-to-GDSII flow: it turns
the Verilog of a lab into the layout of a chip for an open PDK, the SkyWater 130 nm process by
default. It is the successor of OpenLane. Each lab directory has three scripts for it:

| Script | What it does |
|---|---|
| `07_synthesize_for_asic.bash` | Copies the lab into `librelane_designs/<lab>` in the root of the package and runs the whole flow: synthesis, floorplan, placement, clock tree, routing, timing, DRC and LVS. |
| `08_visualize_asic_synthesis_results_1.bash` | Opens the last run in the OpenROAD GUI. |
| `09_visualize_asic_synthesis_results_2.bash` | Opens the last run in KLayout. |

The simplest way to get LibreLane is its AppImage: one file with LibreLane and all its tools.
**The scripts start the AppImage themselves.** You do not need to open an AppImage shell first.

## Requirements

* Linux on x86-64 or ARM64. On Windows, use WSL2; Git Bash is not enough. macOS has no AppImage;
  use LibreLane's Nix or Docker installation and put `librelane` in `PATH` (see below).
* FUSE, as for any AppImage: the `fuse3` or `fuse` package, which most desktop Linux systems
  already have.
* 8 GB of memory, which LibreLane's documentation gives as the minimum.
* Disk space, measured with LibreLane 3.0.17:

  | What | Download | On disk |
  |---|---|---|
  | The AppImage | 1.4 GB | 1.4 GB |
  | The SkyWater 130 nm PDK in `~/.ciel`, downloaded by the first run | 0.34 GB | 2.2 GB |
  | One run of `1_06_binary_counter` | | about 1 GB |

  A run is large because every lab gets a 1 mm × 1 mm die, and the filler cells of the empty
  area take most of the space.

## Installation

1. Download `librelane-devshell-x86_64.AppImage` (or `librelane-devshell-aarch64.AppImage` on
   ARM) from the [latest LibreLane release](https://github.com/librelane/librelane/releases/latest)
   into your home directory or into `~/Downloads`. From a terminal:

   ```bash
   cd ~
   curl -L -O https://github.com/librelane/librelane/releases/download/3.0.17/librelane-devshell-x86_64.AppImage
   chmod a+x librelane-devshell-x86_64.AppImage
   ```

   The SHA-256 sum of the 3.0.17 file is
   `c8ef5ae26b1fc53dd1dd30fe2f1a1da6ab0fdf471dd5a94c2b85d2b3db36833c`.

2. Run the ASIC synthesis of a small lab:

   ```bash
   cd labs/1_basics/1_06_binary_counter
   ./07_synthesize_for_asic.bash
   ```

   The first run downloads the PDK into `~/.ciel`. Later runs use it. For `1_06_binary_counter`,
   the whole flow takes about 20 minutes on a 4-core computer. Most of that time goes to the
   design rule checks of the 1 mm × 1 mm die in Magic and KLayout. At the end, the flow reports
   the checks it ran: no DRC, LVS or antenna errors and no timing violations.

3. Look at the result:

   ```bash
   ./08_visualize_asic_synthesis_results_1.bash   # OpenROAD GUI
   ./09_visualize_asic_synthesis_results_2.bash   # KLayout
   ```

   The viewers need a graphical desktop.

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

The AppImage needs unprivileged user namespaces. Some systems disable them:

* **ALT Linux** and some Debian setups: the AppImage stops with
  `cannot unshare: Operation not permitted`. ALT Linux installs `bwrap` setuid root, so the BGM
  scripts run the AppImage under `bwrap` instead and print
  "Unprivileged user namespaces are disabled, so the LibreLane AppImage runs under bwrap".
  Nothing needs to be changed. To start the AppImage by hand as well, enable the namespaces:

  ```bash
  sudo sysctl -w kernel.unprivileged_userns_clone=1
  ```

  This lasts until the next reboot. To keep it, put the line
  `kernel.unprivileged_userns_clone = 1` into a file in `/etc/sysctl.d`, for example
  `/etc/sysctl.d/99-userns.conf`.

* **Ubuntu 24.04 and newer** restrict the namespaces with AppArmor. LibreLane's documentation
  gives two fixes for the error `cannot write uid_map: Operation not permitted`: install the
  `uidmap` package, and set `kernel.apparmor_restrict_unprivileged_userns = 0` in
  `/etc/sysctl.d/99-userns.conf` (or with `sudo sysctl -w` until the next reboot).

## How the scripts find LibreLane

1. If `LIBRELANE_PATH` is set, it is added to `PATH`.
2. If `librelane` is in `PATH`, the scripts run it directly. This is the case inside a Nix shell,
   or inside the AppImage's own shell, which opens when you run the AppImage without arguments.
3. Otherwise, the scripts use the AppImage named by `LIBRELANE_APPIMAGE`, or the newest
   `librelane*<machine>*.AppImage` in your home directory or in `~/Downloads`. They run
   `<AppImage> librelane <arguments>`, or the same under `bwrap` when the AppImage cannot start by
   itself.

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

The first run needs the Internet to download the PDK. To prepare computers that will be offline,
run one lab once on each computer, or copy the AppImage and the `~/.ciel` directory from a
computer where a run has worked.

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
