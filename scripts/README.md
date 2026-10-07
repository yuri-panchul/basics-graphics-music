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
chosen on the first level. A board with a single configuration is listed
under the name of that configuration and does not open a second menu.

The two levels come from the directory names under `boards` alone:
`fpga_board_config_suffixes` lists the suffixes that mark a configuration
rather than a different board, and `fpga_board_base` removes them. Board
files are not examined, because configurations of the same board comment out
different pins and some Gowin boards have separate configurations for Gowin
EDA and for Yosys.

Removing the longest matching suffix at each step is not enough, because the
suffixes overlap: `tang_primer_20k_dock_no_hdmi_no_tm1638` ends with the
listed suffix `_hdmi_no_tm1638`, while the correct split is `_no_hdmi`
followed by `_no_tm1638`. `fpga_board_base` therefore tries every way to
split the tail and keeps the shortest board name. A consequence is that a
component such as `_pmod`, `_no_hdmi` or `_no_dvi` needs no combined entry of
its own in the list.

Boards that differ by more than a listed suffix stay separate first-level
entries: `de0`, `de0_cv`, `de0_nano` and `de0_nano_soc`; `de1` and `de1_soc`;
`de2` and `de2_115`; `omdazz` and `omdazz_epm570`; `nexys_a7`, `nexys_a7_50`
and `nexys_a7_100`; `tang_mega_138k` and `tang_mega_138k_pro`.

Run the menu regression suite, which checks that the two levels select
exactly the same boards as the one-level menu they replaced:

```sh
python3 scripts/tests/test_fpga_board_menu.py
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
