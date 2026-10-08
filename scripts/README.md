# Notes on Bash scripts

## Choosing Quartus

`steps/00_setup_altera.source_bash` reads the selected board's literal
`DEVICE` assignment from `board_specific.qsf`. It checks release/edition
compatibility and asks each candidate's installed device database about that
exact part. A release without the necessary device package is skipped. This
does not check license availability or guarantee that every lab will compile.

Search priority is:

1. `QUARTUS_ROOTDIR`, pointing directly to the `quartus` directory.
2. The incoming PATH's `quartus` executable (before modifying PATH).
3. `INTEL_FPGA_HOME`, then `ALTERA_HOME`, then `QUARTUS_HOME`. These are parents
   of the vendor directories, not the vendor directories themselves.
4. All default parents together: `$HOME`, `/opt`, `/tools` on Linux, or `/c`,
   `/d`, `/e` on Cygwin/MSYS (Windows drives C:, D:, E:).

An incompatible or incomplete override produces a warning and falls through.
Within each parent tier, all `altera`, `altera_lite`, `altera_std`, `altera_pro`,
`intelFPGA`, `intelFPGA_lite`, `intelFPGA_pro`, and `intelFPGA_std` directories
participate. Installations use `<parent>/<vendor>/<version>/quartus`.
Metadata or `quartus_sh --version` determines edition and numeric version;
directory names do not determine either. For example, `25.1std` can be Lite.

Among compatible candidates in the winning tier, choose the newest Lite/Web
installation if one exists. Otherwise choose the newest Standard/Subscription
or Pro installation, preferring Standard/Subscription on a version tie.
Build numbers participate in the comparison. Remaining ties use stable
collection order: parent order above, vendor order above, then version-directory
glob order. Symlink aliases are deduplicated. No external `sort` is needed.

Cyclone II stops at 13.0 SP1; Cyclone III stops at 13.1. First-generation Cyclone
has different Web and Subscription ceilings. MAX 10 rejects 13.x; its exact
part must exist in the candidate database. DE23-Lite uses Agilex 3 and requires
Pro 25.1 or newer with its device package. The specially named EPM570 legacy
wrapper retains its 13.1 ceiling; other MAX II wrappers do not inherit it.
See the [official device support matrix](https://www.altera.com/design/guidance/software/device-support).

The selected GUI, shell, and programmer come from the same directory, which
is placed first on PATH. Windows discovery tries `bin64` then `bin`.
The selected version directory is still passed to the existing Questa helper;
separating simulator setup is deferred.

Discovery warns about spaces, non-ASCII characters, and special characters
in installation paths, including `! $ % @ ^ & * < > ,`, quotes, and parentheses.
The warning recommends relocating the installation. Quoting keeps discovery
safe, but cannot make Quartus support a path that its own tools reject.
See [Altera's installation-path requirements](https://docs.altera.com/r/docs/683472/26.1/altera-fpga-software-installation-and-licensing/selecting-the-installation-path).

Run the isolated regression suite without Quartus installed:

```sh
python3 scripts/tests/test_quartus_discovery.py
```

## Choosing a board

`steps/00_setup.source_bash` asks for a board with a two-level menu. The
first level lists the boards, the second one the configurations of the board
chosen on the first level. A star marks a board with several configurations;
a board with one configuration does not open a second menu, and choosing it
selects that configuration directly.

The two levels come from the directory names under `boards` alone.
`fpga_board_config_suffixes` lists the suffixes that mark a configuration
rather than a different board, and `fpga_board_base` removes them. Board
files are not examined, because configurations of the same board comment out
different pins and some Gowin boards have separate configurations for Gowin
EDA and for Yosys.

Removing the longest matching suffix at each step is not enough, because the
suffixes overlap: `tang_primer_20k_dock_no_hdmi_no_tm1638` ends with the
listed suffix `_hdmi_no_tm1638`, while the correct split is `_no_hdmi`
followed by `_no_tm1638`. `fpga_board_base` therefore tries every way to
split the tail and keeps the shortest board name.

`fpga_board_families` handles the two products that are sold in two sizes:
Nexys A7-50T and A7-100T, and Arty A7-35T and A7-100T. They differ in the part
number in `board_specific.tcl`, so each pair is one board with two
configurations. It lists the four directories by name rather than a suffix
such as `_100`, because a number at the end of a name does not reliably mean a
size - a future `new_board_100` may well be a different product from
`new_board`. The mapping is applied by `fpga_board_base` after
`fpga_board_base_search` has removed the suffixes, so it happens once and
cannot change which way an overlapping suffix is split.

Boards that differ by more than a listed suffix stay separate first-level
entries: `de0`, `de0_cv`, `de0_nano` and `de0_nano_soc`; `de1` and `de1_soc`;
`de2` and `de2_115`; `nexys4` and `nexys4_ddr`; `omdazz` and `omdazz_epm570`;
`tang_mega_138k` and `tang_mega_138k_pro`. `_ecp5` names the FPGA and is part
of the board name, which is why the directories are called
`colorlight75b_ecp5_tm1638_yosys` rather than `colorlight75b_tm1638_ecp5_yosys`.

Two kinds of directory are left out of the menu. `fpga_board_non_boards`
lists directories that are not boards at all, currently only
`zzz_postponed_and_retired`; those are dropped from `available_fpga_boards`
as well, so they appear neither in the selection file nor in the validity
check. A configuration whose name ends in `_hackathon` is chosen by naming it
in `hackathon_top.sv` instead, so it is left out of the menu but kept in the
selection file, where it can still be uncommented by hand.

`fpga_board_legacy_aliases` names configurations kept only so that older
notes keep working. `nexys_a7` has the same part and the same pins as
`nexys_a7_100`, so the second level shows it as
`nexys_a7 (alias of nexys_a7_100)`.

The menu numbers are read with `fpga_board_menu_choice`, which keeps the
digits of the answer and forces base ten. Bash `select` accepts `8`, `08`,
` 8`, `+8` for item eight and `010` for item ten, but Bash arithmetic reads a
leading zero as octal, so `$(( REPLY - 1 ))` would turn `010` into item eight
and fail outright on `08`.

The first level is sorted by board name with `fpga_board_sort`, which is why
`de0_nano` comes before `de0_nano_soc`: the directory listing has
`de0_nano_soc_vga666` before `de0_nano_vga666`, because "s" comes before "v".
That sort is written in Bash rather than calling `sort`, because Windows has
its own `sort.exe` that may come first on `PATH` and does not understand the
Unix options. Sorting 52 names this way costs about a millisecond, which is
less than starting `sort` would.

The directory listing itself is sorted with `LC_ALL=C`, and
`fpga_board_sort` makes `LC_ALL` local for the same reason, so the numbers in
the menu are the same on every machine. Under a UTF-8 locale `sort` ignores the
underscore at the first comparison level, which swaps `de2_115` and
`de23_lite` - and then "choose number 26" means two different boards on two
different laptops.

Besides a number, the menu takes `e` or `E` to exit on either level, and `b`
or `B` to go back on the second one. They are recognised where `select`
reports that the answer was not a menu number, so they cost nothing when the
answer is a number, and any other letter is still rejected as before.

`select_fpga_board` returns non-zero when the user cancels, rather than
exiting the script itself, and keeps `PS3` and `REPLY` local.

Run the menu regression suite:

```sh
python3 scripts/tests/test_fpga_board_menu.py
```

Add `--baseline <path to an older 00_setup.source_bash>` to replay every
selection through both the old flat menu and the two-level menu and compare
the chosen board, the chosen toolchain and the selection file:

```sh
git show 77959f67:scripts/steps/00_setup.source_bash > /tmp/old_setup.source_bash
python3 scripts/tests/test_fpga_board_menu.py --baseline /tmp/old_setup.source_bash
```

## Strict Bash settings

[The article about these settings.](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail)
[Arguments
against.](https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk)
[Another idea.](http://redsymbol.net/articles/unofficial-bash-strict-mode)

```
#  set -e           - Exit immediately if a command exits with a non-zero
#                     status.  Note that failing commands in a conditional
#                     statement will not cause an immediate exit.
#
#  set -o pipefail  - Sets the pipeline exit code to zero only if all
#                     commands of the pipeline exit successfully.
#
#  set -u           - Causes the bash shell to treat unset variables as an
#                     error and exit immediately.
#
#  set -x           - Causes bash to print each command before executing it.
#
#  set -E           - Improves handling ERR signals

set -Eeuxo pipefail
```
