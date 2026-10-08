# Notes on Bash scripts

## Choosing an FPGA board

The board menu in `steps/00_setup.source_bash` first lists board names or
families, then lists their configurations using complete directory names.
A trailing ` *` marks a group with multiple visible configurations; a short
legend explains it. A board with only one configuration is selected immediately.
The second menu
has `back` and `exit`; invalid input retries the current menu. Exiting or closing
standard input leaves an existing selection file untouched. Numbers with leading
zeros are decimal: `08`, `09`, and `010` select items 8, 9, and 10.

`fpga_board_base_name` groups names by removing a complete trailing sequence of
known configuration suffixes. For example,
`tang_nano_9k_50mhz_hdmi_no_tm1638` belongs to `tang_nano_9k`. Matching the whole
sequence handles overlapping suffixes such as `_no_hdmi` and `_hdmi_tm1638`
without leaving a bogus board name ending in `_no`.

`_ecp5` is part of the board name, so `colorlight75b_ecp5_tm1638_yosys`
belongs to `colorlight75b_ecp5`, and `karnix_ecp5_yosys` to `karnix_ecp5`.
Only specific PMOD compounds such as `_pmod_hdmi` and
`_pmod_hub75e_led_matrix` are suffixes; an unknown ending such as `_pmod`
is retained. `_hackathon` is not a configuration suffix for grouping.

Explicit family rules group `nexys_a7`, `nexys_a7_50`, and `nexys_a7_100`
under `nexys_a7`, and the `arty_a7_35` and `arty_a7_100` configurations
under `arty_a7`. These chip variants keep their original directories and
board files. The legacy `nexys_a7` entry is displayed as
`nexys_a7 (alias of nexys_a7_100)`; selecting it still saves `nexys_a7`.
`nexys4` and `nexys4_ddr` remain separate, as do `de0`, `de0_nano`,
`de0_nano_soc`, `de1`/`de1_soc`, `de2`/`de2_115`, and `omdazz`/`omdazz_epm570`.

The retired container `zzz_postponed_and_retired` is ignored. Directories
ending in `_hackathon` are hidden from the menu; the existing
`hackathon_top.sv` override can still select them before menu discovery.
Saved valid selections retain their existing role.

`fpga_board_sort_discovery` checks `/usr/bin/sort`, `/bin/sort`, then PATH's
`sort` for correct C ordering. Every directory sort uses `LC_ALL=C` with the
verified command. The probe rejects failing or incompatible utilities, including
Windows sort with different ordering. No `sort -u` support is required; Bash
deduplicates board names. If no compatible sorter exists, setup reports the
missing dependency. The caller's locale and menu prompt variables are preserved.
The first menu is sorted by the derived board names, so `de0_nano` precedes
`de0_nano_soc`. Variants retain directory-name order. Names alone build the menu,
without reading pin constraints or requiring installed EDA tools.

The current 110 eligible directory choices appear in 52 board/family groups.
`fpga_board_selection` retains its flat format: the selected configuration's
original name is uncommented and other eligible choices are commented. Display
annotations and first-level markers never enter the saved name or toolchain
dispatch.

Run the menu tests without installing EDA tools:

```sh
python3 -B scripts/tests/test_board_menu.py
```

The tests run the actual setup script in temporary repositories with empty board
directories and stubbed EDA setup functions. Independent expected results come
from the board catalog plus explicit family and ECP5 naming rules. They check
all retained configurations, exact saved files, toolchains, menu traversal,
aliases, filtering, decimal input, locale independence, sort discovery, caller
state, retries, cancellation, saved choices, and file-driven hackathon overrides.
Platform-branch tests on Linux emulate `OSTYPE`; they are not native Windows or
macOS verification.

To compare retained selections with the original flat menu:

```sh
git show c055dfe3:scripts/steps/00_setup.source_bash > /tmp/bgm-flat-board-setup.source_bash
python3 -B scripts/tests/test_board_menu.py --baseline /tmp/bgm-flat-board-setup.source_bash
```

The baseline check accounts for the intentionally hidden entries in the new
selection file while requiring the same selected identifier and toolchain.

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
