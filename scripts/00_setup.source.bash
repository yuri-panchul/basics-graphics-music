set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

setup_source_bash_already_run=1

#-----------------------------------------------------------------------------
#
#   Directory setup
#
#-----------------------------------------------------------------------------

package_dir=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
board_dir="$package_dir/boards"
lab_dir="$package_dir/labs"
script_dir="$package_dir/scripts"

#-----------------------------------------------------------------------------

script=$(basename "$0")
log="$PWD/log.txt"

cd $(dirname "$0")
mkdir -p run
cd run

#-----------------------------------------------------------------------------
#
#   Platform-specific workarounds
#
#-----------------------------------------------------------------------------

# A workaround for a find problem when running bash under Microsoft Windows

find_to_run=find
true_find=/usr/bin/find

if [ -x "$true_find" ]
then
    find_to_run="$true_find"
fi

#-----------------------------------------------------------------------------
#
#   General routines
#
#-----------------------------------------------------------------------------

error ()
{
    printf "$script: error: $*\n" 1>&2
    exit 1
}

#-----------------------------------------------------------------------------

warning ()
{
    printf "$script: warning: $*\n" 1>&2
}

#-----------------------------------------------------------------------------

info ()
{
    printf "$script: $*\n" 1>&2
}

#-----------------------------------------------------------------------------

is_command_available ()
{
    command -v $1 &> /dev/null
}

#-----------------------------------------------------------------------------

is_command_available_or_error ()
{
    is_command_available $1 ||  \
        error "program $1$2 is not in the path or cannot be run$3"
}

#-----------------------------------------------------------------------------

is_command_available_or_error_and_install ()
{
    if [ -n "${2-}" ]; then
        package=$2
    else
        package=$1
    fi

    if [ "$OSTYPE" = "linux-gnu" ]; then
        how_to_install=". To install, run either: \"sudo apt-get install $package\" or \"sudo yum install $package\". If it does not work, google the instructions."
    else
        how_to_install=
    fi

    is_command_available_or_error $1 "" "$how_to_install"
}

#-----------------------------------------------------------------------------
#
#   Intel FPGA Setup - Quartus
#
#-----------------------------------------------------------------------------

intel_fpga_setup_quartus ()
{
       [ "$OSTYPE" = "linux-gnu" ]  \
    || [ "$OSTYPE" = "cygwin"    ]  \
    || [ "$OSTYPE" = "msys"      ]  \
    || return

    intelfpga_install_dir=intelFPGA_lite
    quartus_dir=quartus

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        intelfpga_install_parent_dir="$HOME"
        quartus_bin_dir=bin

        if ! [ -d "$intelfpga_install_parent_dir/$intelfpga_install_dir" ]
        then
            intelfpga_install_parent_dir_first="$intelfpga_install_parent_dir"
            intelfpga_install_parent_dir=/opt
        fi

    elif  [ "$OSTYPE" = "cygwin"    ]  \
       || [ "$OSTYPE" = "msys"      ]
    then
        intelfpga_install_parent_dir=/c
        quartus_bin_dir=bin64
    else
        error "this script does not support your OS / platform '$OSTYPE'"
    fi

    if ! [ -d "$intelfpga_install_parent_dir/$intelfpga_install_dir" ]
    then
        error "expected to find '$intelfpga_install_dir' directory"  \
              " in '$intelfpga_install_parent_dir'"
    fi

    #-------------------------------------------------------------------------

    if ! [ -d "$intelfpga_install_parent_dir/$intelfpga_install_dir" ]
    then
        if [ -z "${intelfpga_install_parent_dir_first-}" ]
        then
            error "expected to find '$intelfpga_install_dir' directory"  \
                  "in '$intelfpga_install_parent_dir'"
        else
            error "expected to find '$intelfpga_install_dir' directory"  \
                  "either in '$intelfpga_install_parent_dir_first'"      \
                  "or in '$intelfpga_install_parent_dir'"
        fi
    fi

    #-------------------------------------------------------------------------

    find_command="$find_to_run $intelfpga_install_parent_dir/$intelfpga_install_dir -mindepth 1 -maxdepth 1 -type d -print"
    first_version_dir=$($find_command -quit)

    if [ -z "${first_version_dir-}" ]
    then
        error "cannot find any version of Intel FPGA installed in "  \
              "'$intelfpga_install_parent_dir/$intelfpga_install_dir'"
    fi

    #-------------------------------------------------------------------------

    export QUARTUS_ROOTDIR="$first_version_dir/$quartus_dir"
    export PATH="${PATH:+$PATH:}$QUARTUS_ROOTDIR/$quartus_bin_dir"

    #-------------------------------------------------------------------------

    all_version_dirs=$($find_command | xargs echo)

    if [ "$first_version_dir" != "$all_version_dirs" ]
    then
        warning 1 "multiple Intel FPGA versions installed in"  \
                "'$intelfpga_install_parent_dir/$intelfpga_install_dir':"  \
                "'$all_version_dirs'"

        info "QUARTUS_ROOTDIR=$QUARTUS_ROOTDIR"
        info "PATH=$PATH"
        info "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    fi

    #-------------------------------------------------------------------------

                   [ -d "$QUARTUS_ROOTDIR" ]  \
    || error "directory '$QUARTUS_ROOTDIR' expected"

                   [ -d "$QUARTUS_ROOTDIR/$quartus_bin_dir" ]  \
    || error "directory '$QUARTUS_ROOTDIR/$quartus_bin_dir' expected"

    #-------------------------------------------------------------------------

    # Workarounds for Quartus library problems
    # that are uncovered under RED OS from https://www.red-soft.ru

    if    ! [ -f /usr/lib64/libcrypt.so.1 ] \
       &&   [ -f /usr/lib64/libcrypt.so   ]
    then
        ln -sf /usr/lib64/libcrypt.so libcrypt.so.1
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$PWD"
    fi
}

#-----------------------------------------------------------------------------
#
#   Intel FPGA Setup - Questa
#
#-----------------------------------------------------------------------------

intel_fpga_setup_questa ()
{
       [ "$OSTYPE" = "linux-gnu" ]  \
    || [ "$OSTYPE" = "cygwin"    ]  \
    || [ "$OSTYPE" = "msys"      ]  \
    || return

    if    [ -z "${intelfpga_install_dir-}"        ]  \
       || [ -z "${intelfpga_install_parent_dir-}" ]  \
       || [ -z "${first_version_dir-}"            ]
    then
        error "Intel FPGA Quartus was supposed to be setup first. "  \
              "Probably internal error."
    fi

    #-------------------------------------------------------------------------

    questa_dir=questa_fse

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        questa_bin_dir=bin
        questa_lib_dir=linux_x86_64

    elif  [ "$OSTYPE" = "cygwin"    ]  \
       || [ "$OSTYPE" = "msys"      ]
    then
        questa_bin_dir=win64
        questa_lib_dir=win64
    else
        error "this script does not support your OS / platform '$OSTYPE'"
    fi

    #-------------------------------------------------------------------------

    default_lm_license_file="$HOME/flexlm/license.dat"

    if [ -f "$default_lm_license_file" ]
    then
        if [ -z "${LM_LICENSE_FILE-}" ] ; then
            export LM_LICENSE_FILE="$default_lm_license_file"
        fi

        if [ -z "${MGLS_LICENSE_FILE-}" ] ; then
            export MGLS_LICENSE_FILE="$default_lm_license_file"
        fi
    fi

    #-------------------------------------------------------------------------

    # Check if Quartus is installed without Questa
    [ -d "$first_version_dir/$questa_dir" ] || return 0

    export QUESTA_ROOTDIR="$first_version_dir/$questa_dir"
    export PATH="${PATH:+$PATH:}$QUESTA_ROOTDIR/$questa_bin_dir"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$QUESTA_ROOTDIR/$questa_lib_dir"

    #-------------------------------------------------------------------------

                   [ -d "$QUESTA_ROOTDIR" ]  \
    || error "directory '$QUESTA_ROOTDIR' expected"

                   [ -d "$QUESTA_ROOTDIR/$questa_bin_dir" ]  \
    || error "directory '$QUESTA_ROOTDIR/$questa_bin_dir' expected"
}

#-----------------------------------------------------------------------------
#
#   Icarus Verilog setup
#
#-----------------------------------------------------------------------------

icarus_verilog_setup ()
{
    alt_icarus_install_path="$HOME/install/iverilog"

    if [ -d "$alt_icarus_install_path" ]
    then
        export PATH="${PATH:+$PATH:}$alt_icarus_install_path/bin"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$alt_icarus_install_path/lib"
    fi
}

#-----------------------------------------------------------------------------
#
#   FPGA Board setup
#
#-----------------------------------------------------------------------------

create_fpga_board_select_file()
{
    > "$select_file"

    for i_fpga_board in $available_fpga_boards
    do
        comment="# "
        [ $i_fpga_board == $fpga_board ] && comment=""
        printf "$comment$i_fpga_board\n" >> "$select_file"
    done

    info "Created an FPGA board selection file: \"$select_file\""
}

fpga_board_setup ()
{
    if ! [[ $script =~ fpga ]] ; then
        return
    fi

    available_fpga_boards=$($find_to_run "$board_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f ')

    select_file="$package_dir/fpga_board_selection"

    if [ -f "$select_file" ] && [ -n "${force_removing_fpga_board_selection-}" ]
    then
        fpga_board=$(set +eo pipefail; grep -o '^[^#/-]*' "$select_file" | grep -m 1 -o '^[[:alnum:]_]*')

        select_file_contents=$(cat "$select_file")

        if [ -n "${fpga_board-}" ] ; then
           info "The current contents of \"$select_file:\"" \
                "\n\n$select_file_contents" \
                "\n\nThe currently selected FPGA board: $fpga_board"
        else
           info "Currently no FPGA board is selected in \"$select_file:\"" \
                "\n\n$select_file_contents\n\n"
        fi

        # read:
        #
        # -n nchars return after reading NCHARS characters rather than waiting
        #           for a newline, but honor a delimiter if fewer than
        #           NCHARS characters are read before the delimiter
        #
        # -p prompt output the string PROMPT without a trailing newline before
        #           attempting to read
        #
        # -r        do not allow backslashes to escape any characters
        # -s        do not echo input coming from a terminal

        read -n 1 -r -p "Are you sure to overwrite FPGA board selection file at \"$select_file\" ? "
        printf "\n"

        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            rm -rf "$select_file"
        fi
    fi

    if ! [ -f "$select_file" ]
    then
        extra_info=

        if [ -z "${force_removing_fpga_board_selection-}" ] ; then
            extra_info="There is no FPGA board selection file at \"$select_file\" "
        fi

        info "${extra_info}Please select an FPGA board amoung the following supported:"

        PS3="Your choice (a number): "

        select fpga_board in $available_fpga_boards exit
        do
            if [ -z "${fpga_board-}" ] ; then
                info "Invalid FPGA board choice, please choose one of the listed numbers again"
                continue
            fi

            if [ $fpga_board == "exit" ] ; then
                error "FPGA board is not selected, please run the script again"
            fi

            info "FPGA board selected: $fpga_board"
            break
        done

        create_fpga_board_select_file

        read -n 1 -r -p "Would you like to create run directories for synthesis based on your FPGA board selection? "
        printf "\n"

        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            info TODO
        fi
    fi

    fpga_board=$(set +eo pipefail; grep -o '^[^#/-]*' "$select_file" | grep -m 1 -o '^[[:alnum:]_]*')

    select_file_contents=$(cat "$select_file")

    [ -n "${fpga_board-}" ] || \
       error "No FPGA board is selected in \"$select_file:\"" \
             "\n\n$select_file_contents\n\n"
}

#-----------------------------------------------------------------------------
#
#   Calling routines
#
#-----------------------------------------------------------------------------

if [ -z "${MGLS_LICENSE_FILE-}" ] ; then
    is_command_available quartus || intel_fpga_setup_quartus
    is_command_available vsim    || intel_fpga_setup_questa
fi

is_command_available iverilog || icarus_verilog_setup

fpga_board_setup
