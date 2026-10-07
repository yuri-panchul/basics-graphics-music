# Notes on Bash scripts

## Choosing an FPGA board

The board menu in `steps/00_setup.source_bash` first lists board models, then
lists the selected board's configurations using their complete directory names.
A board with only one configuration is selected immediately. The second menu
has `back` and `exit`; invalid input retries the current menu. Exiting or closing
standard input leaves an existing selection file untouched.

`fpga_board_base_name` groups directory names by removing a trailing sequence of
known configuration suffixes. For example,
`tang_nano_9k_50mhz_hdmi_no_tm1638` belongs to `tang_nano_9k`. Matching the whole
sequence prevents overlapping suffixes such as `_no_hdmi` and `_hdmi_tm1638`
from leaving a bogus board name ending in `_no`. The suffix list also recognizes
the existing `_no_dvi`, `_pmod_hub75e_led_matrix`, and `_ecp5_yosys` forms.
Unknown endings remain part of the board name; adding a new configuration naming
convention may require extending this list.

Hardware names such as `de0`, `de0_nano`, `de0_nano_soc`, `de1`, `de1_soc`,
`de2`, `de2_115`, `omdazz`, and `omdazz_epm570` remain separate. Directory names
alone build the menu; board constraints and installed EDA tools are not needed
to group the choices. Board and variant order follow the existing sorted
directory list, without introducing another external sorting command.

The selected value is still the exact original configuration directory name.
`fpga_board_selection` retains its flat format with every original entry and
only the selected configuration uncommented. Saved selections, hackathon
overrides, and the subsequent toolchain selection retain their existing roles.
The original 113 directory choices are reachable through 56 board entries,
including the existing `nexys_a7` and `zzz_postponed_and_retired` entries that
are not models in the board catalog.

Run the menu tests without installing EDA tools:

```sh
python3 -B scripts/tests/test_board_menu.py
```

The tests run the actual setup script in a temporary repository with empty
board directories and stubbed EDA setup functions. Expected board groups come
from the independent board catalog, not the suffix-matching implementation.
They select every configuration and check its saved file and toolchain, along
with retries, Back/Exit, EOF, saved choices, and hackathon overrides.

To compare all successful selections directly with the original flat menu:

```sh
git show 77959f67:scripts/steps/00_setup.source_bash > /tmp/bgm-flat-board-setup.source_bash
python3 -B scripts/tests/test_board_menu.py --baseline /tmp/bgm-flat-board-setup.source_bash
```

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
