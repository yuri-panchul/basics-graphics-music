# ASIC synthesis with the LibreLane AppImage

Run the lab's ASIC scripts from an ordinary Bash terminal. Each script starts
the LibreLane AppImage with its command, waits for it to finish, and returns
its exit status. You do not need to open an AppImage shell first.

## Install once

Use Linux, or a Linux environment such as WSL on Windows. Download
`librelane-devshell-x86_64.AppImage` for x86-64 or
`librelane-devshell-aarch64.AppImage` for ARM64 from the
[LibreLane 3.0.17 release](https://github.com/librelane/librelane/releases/tag/3.0.17).
This is the release whose command interface was reviewed for these scripts;
the scripts do not enforce its version or download/update the image themselves.
See the [official Linux prerequisites](https://librelane.readthedocs.io/en/stable/installation/appimage_installation/installation_linux.html).

Leave the file in `~/Downloads` or move it to your home directory, keeping its
original filename. Give it execution permission, for example:

```bash
chmod +x "$HOME/Downloads/librelane-devshell-$(uname -m).AppImage"
```

For an image in another location, set its **absolute filename**:

```bash
export LIBRELANE_APPIMAGE="/absolute/path/to/librelane-devshell-x86_64.AppImage"
```

Set this in the terminal where you run the labs, or in your Bash startup file
if you want it for future terminals. A path containing spaces must be quoted.
`LIBRELANE_APPIMAGE` names a file; the older `LIBRELANE_PATH` names a directory
containing a native `librelane` executable.

An optional installation check can also run without entering an AppImage shell:

```bash
"$LIBRELANE_APPIMAGE" librelane --version
"$LIBRELANE_APPIMAGE" librelane --smoke-test
```

These examples assume you set `LIBRELANE_APPIMAGE` above; otherwise substitute
the downloaded image's filename. The smoke test exercises the real tool flow
and may need network access and PDK storage. A full lab run also needs the PDK
selected by LibreLane; see [PDK management](https://librelane.readthedocs.io/en/stable/usage/about_pdks.html).

## Run a lab

Starting at the repository root:

```bash
cd labs/1_basics/1_01_and_or_not_xor_de_morgan
./07_synthesize_for_asic.bash --run-tag first-layout
./08_visualize_asic_synthesis_results_1.bash --run-tag first-layout
./09_visualize_asic_synthesis_results_2.bash --run-tag first-layout
```

Step 07 runs the full `Classic` flow by default. Step 08 opens OpenROAD;
step 09 opens KLayout. Each viewer waits until its application closes.
Without `--run-tag`, synthesis uses LibreLane's generated run name and viewers
use `--last-run`. Viewer scripts need a graphical Linux session and an
existing run with the appropriate layout state.

All three scripts forward extra arguments to LibreLane. For a shorter
synthesis checkpoint:

```bash
./07_synthesize_for_asic.bash --run-tag synthesis-only \
    --to Checker.NetlistAssignStatements
```

That checkpoint does not create a placed/routed layout. Use a full flow before
the usual layout-viewer commands. To open an intermediate saved state, pass
`--with-initial-state /absolute/path/to/state_out.json` to step 08 or 09 along
with the run tag. The state must contain the database needed by that viewer.
Relative paths in forwarded options are resolved from the staged design
directory, so absolute filenames are simplest.

Sources and configuration are staged at
`<repository>/librelane_designs/<lab-directory-name>/`; run outputs are under
its `runs/<run-tag>/` directory. Running step 07 again refreshes staged sources
and Tcl files but retains previous run directories. Use distinct run tags
when comparing results. A lab's `asic_config.tcl`, when present, replaces the
shared `config.tcl`.

## Runtime selection and implementation

The selection order is:

1. Explicit `LIBRELANE_APPIMAGE` executable filename.
2. Native `librelane` in the explicit `LIBRELANE_PATH` directory.
3. `librelane` already on `PATH`, including an active Nix/AppImage shell.
4. `~/librelane-devshell-$(uname -m).AppImage`, then the same name in
   `~/Downloads`.

An explicitly set but empty, missing, or nonexecutable override is an error.
Use `unset LIBRELANE_APPIMAGE LIBRELANE_PATH` to return to automatic discovery.
If a native `librelane` is on `PATH` and you want the AppImage instead, set
`LIBRELANE_APPIMAGE` explicitly. Runtime selection applies only to ASIC scripts.

`steps/00_setup_libre_lane.source_bash` owns runtime discovery,
`run_librelane`, `synthesize_for_asic_librelane`, and viewer dispatch.
`steps/07_synthesize_for_asic.source_bash` sources common setup and calls
`synthesize_for_asic_librelane "$@"`. Both viewer steps use the same runtime.
For an AppImage, the executed command has this shape:

```text
/absolute/path/to/LibreLane.AppImage librelane --flow Classic ... config.tcl
```

The shell passes an argument array directly, preserving spaces and literal
characters. It does not send commands through an interactive shell or `eval`.
LibreLane's [3.0.17 AppImage CI smoke test](https://github.com/librelane/librelane/blob/64ef80802d3d189b476636d2a6b17888c03304ee/.github/workflows/ci.yml#L367)
uses this same command-passing interface. The caller's environment, including
PDK and display settings, is inherited by the image.

Source preparation runs on the host before LibreLane starts. CPU labs still
need the repository's existing host-side RARS/Java or RISC-V software tools.
The AppImage does not install those lab-specific dependencies.

## Troubleshooting and validation limits

- `LIBRELANE_APPIMAGE must name an executable AppImage file`: check the
  absolute filename and execution permission. Do not put extra command
  arguments in the variable.
- `Cannot find a LibreLane runtime`: install the image in a searched location
  or set the explicit filename above.
- A FUSE mount/device error happens before LibreLane starts. Check FUSE support
  in the host or container where you launch the image.
- `cannot unshare: Operation not permitted` or a `uid_map` error means the
  AppImage's namespace setup was refused. Consult the
  [upstream namespace troubleshooting](https://librelane.readthedocs.io/en/stable/installation/appimage_installation/installation_linux.html#troubleshooting)
  and the host/container policy. This is separate from the wrapper command;
  the scripts do not change system security settings.
- A missing staged configuration means step 07 has not prepared this lab yet.
  A missing run or layout state is subsequently diagnosed by LibreLane. A
  failed flow's exit status is preserved and no success message is printed.

Run the wrapper regression tests without a PDK or GUI:

```bash
python3 -B scripts/tests/test_librelane.py
```

They execute the actual lab launchers with recording AppImage/native commands
and cover argument boundaries, runtime precedence, source archives and paths
with spaces, staging, failures, and viewer run selection. If Icarus Verilog is
installed, they also elaborate the real basic lab's staged sources. These
checks do not establish a successful LibreLane physical flow or GUI session.
During implementation, the installed real AppImage failed at namespace setup
before LibreLane started, so full synthesis and viewer execution remain
unvalidated on that host.

The basic lab's required neutral ASIC header is now staged. The wider source
manifest, multi-program ROM, wrapper-interface, and timing findings in the
[support review](../misc/ai_sessions/20261120_libre_lane_support/codex/libre_lane_support_review.html)
still need separate work; the presence of an ASIC launcher does not certify
every lab for physical implementation.
