set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

setup_source_bash_already_run=1

#-----------------------------------------------------------------------------
#
#   Directory setup
#
#-----------------------------------------------------------------------------

script=$(basename "$0")
log="$PWD/log.txt"

cd $(dirname "$0")
mkdir -p run
cd run

#-----------------------------------------------------------------------------

package_dir=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")
board_dir="$package_dir/boards"
lab_dir="$package_dir/labs"
script_dir="$package_dir/scripts"

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

    INTELFPGA_INSTALL_DIR=intelFPGA_lite
    QUARTUS_DIR=quartus

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        INTELFPGA_INSTALL_PARENT_DIR="$HOME"
        QUARTUS_BIN_DIR=bin

        if ! [ -d "$INTELFPGA_INSTALL_PARENT_DIR/$INTELFPGA_INSTALL_DIR" ]
        then
            INTELFPGA_INSTALL_PARENT_DIR_FIRST="$INTELFPGA_INSTALL_PARENT_DIR"
            INTELFPGA_INSTALL_PARENT_DIR=/opt
        fi

    elif  [ "$OSTYPE" = "cygwin"    ]  \
       || [ "$OSTYPE" = "msys"      ]
    then
        INTELFPGA_INSTALL_PARENT_DIR=/c
        QUARTUS_BIN_DIR=bin64
    else
        error "this script does not support your OS / platform '$OSTYPE'"
    fi

    if ! [ -d "$INTELFPGA_INSTALL_PARENT_DIR/$INTELFPGA_INSTALL_DIR" ]
    then
        error "expected to find '$INTELFPGA_INSTALL_DIR' directory"  \
              " in '$INTELFPGA_INSTALL_PARENT_DIR'"
    fi

    #-------------------------------------------------------------------------

    if ! [ -d "$INTELFPGA_INSTALL_PARENT_DIR/$INTELFPGA_INSTALL_DIR" ]
    then
        if [ -z "${INTELFPGA_INSTALL_PARENT_DIR_FIRST-}" ]
        then
            error "expected to find '$INTELFPGA_INSTALL_DIR' directory"  \
                  "in '$INTELFPGA_INSTALL_PARENT_DIR'"
        else
            error "expected to find '$INTELFPGA_INSTALL_DIR' directory"  \
                  "either in '$INTELFPGA_INSTALL_PARENT_DIR_FIRST'"      \
                  "or in '$INTELFPGA_INSTALL_PARENT_DIR'"
        fi
    fi

    #-------------------------------------------------------------------------

    FIND_COMMAND="$find_to_run $INTELFPGA_INSTALL_PARENT_DIR/$INTELFPGA_INSTALL_DIR -mindepth 1 -maxdepth 1 -type d -print"
    FIRST_VERSION_DIR=$($FIND_COMMAND -quit)

    if [ -z "${FIRST_VERSION_DIR-}" ]
    then
        error "cannot find any version of Intel FPGA installed in "  \
              "'$INTELFPGA_INSTALL_PARENT_DIR/$INTELFPGA_INSTALL_DIR'"
    fi

    #-------------------------------------------------------------------------

    export QUARTUS_ROOTDIR="$FIRST_VERSION_DIR/$QUARTUS_DIR"
    export PATH="${PATH:+$PATH:}$QUARTUS_ROOTDIR/$QUARTUS_BIN_DIR"

    #-------------------------------------------------------------------------

    ALL_VERSION_DIRS=$($FIND_COMMAND | xargs echo)

    if [ "$FIRST_VERSION_DIR" != "$ALL_VERSION_DIRS" ]
    then
        warning 1 "multiple Intel FPGA versions installed in"  \
                "'$INTELFPGA_INSTALL_PARENT_DIR/$INTELFPGA_INSTALL_DIR':"  \
                "'$ALL_VERSION_DIRS'"

        info "QUARTUS_ROOTDIR=$QUARTUS_ROOTDIR"
        info "PATH=$PATH"
        info "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    fi

    #-------------------------------------------------------------------------

                   [ -d "$QUARTUS_ROOTDIR" ]  \
    || error "directory '$QUARTUS_ROOTDIR' expected"

                   [ -d "$QUARTUS_ROOTDIR/$QUARTUS_BIN_DIR" ]  \
    || error "directory '$QUARTUS_ROOTDIR/$QUARTUS_BIN_DIR' expected"

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

    if    [ -z "${INTELFPGA_INSTALL_DIR-}"        ]  \
       || [ -z "${INTELFPGA_INSTALL_PARENT_DIR-}" ]  \
       || [ -z "${FIRST_VERSION_DIR-}"            ]
    then
        error "Intel FPGA Quartus was supposed to be setup first. "  \
              "Probably internal error."
    fi

    #-------------------------------------------------------------------------

    QUESTA_DIR=questa_fse

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        QUESTA_BIN_DIR=bin
        QUESTA_LIB_DIR=linux_x86_64

    elif  [ "$OSTYPE" = "cygwin"    ]  \
       || [ "$OSTYPE" = "msys"      ]
    then
        QUESTA_BIN_DIR=win64
        QUESTA_LIB_DIR=win64
    else
        error "this script does not support your OS / platform '$OSTYPE'"
    fi

    #-------------------------------------------------------------------------

    DEFAULT_LM_LICENSE_FILE="$HOME/flexlm/license.dat"

    if [ -f "$DEFAULT_LM_LICENSE_FILE" ]
    then
        if [ -z "${LM_LICENSE_FILE-}" ] ; then
            export LM_LICENSE_FILE="$DEFAULT_LM_LICENSE_FILE"
        fi

        if [ -z "${MGLS_LICENSE_FILE-}" ] ; then
            export MGLS_LICENSE_FILE="$DEFAULT_LM_LICENSE_FILE"
        fi
    fi

    #-------------------------------------------------------------------------

    # Check if Quartus is installed without Questa
    [ -d "$FIRST_VERSION_DIR/$QUESTA_DIR" ] || return 0

    export QUESTA_ROOTDIR="$FIRST_VERSION_DIR/$QUESTA_DIR"
    export PATH="${PATH:+$PATH:}$QUESTA_ROOTDIR/$QUESTA_BIN_DIR"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$QUESTA_ROOTDIR/$QUESTA_LIB_DIR"

    #-------------------------------------------------------------------------

                   [ -d "$QUESTA_ROOTDIR" ]  \
    || error "directory '$QUESTA_ROOTDIR' expected"

                   [ -d "$QUESTA_ROOTDIR/$QUESTA_BIN_DIR" ]  \
    || error "directory '$QUESTA_ROOTDIR/$QUESTA_BIN_DIR' expected"
}

#-----------------------------------------------------------------------------
#
#   Icarus Verilog setup
#
#-----------------------------------------------------------------------------

icarus_verilog_setup ()
{
    ALT_ICARUS_INSTALL_PATH="$HOME/install/iverilog"

    if [ -d "$ALT_ICARUS_INSTALL_PATH" ]
    then
        export PATH="${PATH:+$PATH:}$ALT_ICARUS_INSTALL_PATH/bin"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$ALT_ICARUS_INSTALL_PATH/lib"
    fi
}

#-----------------------------------------------------------------------------
#
#   FPGA Board setup
#
#-----------------------------------------------------------------------------

fpga_board_setup ()
{
    available_fpga_boards=$($find_to_run "$board_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f ')

    select_file="$package_dir/fpga_board_selection"

    if ! [ -f $select_file ]
    then
        info "There is no FPGA board selection file at \"$select_file\"" \
             "Please select an FPGA board amoung the following supported:"

        PS3="Your choice: "

        select fpga_board in $available_fpga_boards exit
        do
            if [ $fpga_board == "exit" ] ; then
                error "FPGA board is not selected, please run the script again"
            fi

            if [ -z "${fpga_board-}" ] ; then
                error "Invalid FPGA board choice, please run the script again"
            fi

            info "FPGA board selected: $fpga_board"
            break
        done

        > $select_file
        
        for i_fpga_board in $available_fpga_boards
        do
            comment="# "
            [ $i_fpga_board == $fpga_board ] && comment=""
            printf "$comment$i_fpga_board\n" >> $select_file
        done

        info "Created an FPGA board selection file: $select_file"
    fi

    fpga_board=$(set +eo pipefail; grep -o '^[^#/-]*' "$select_file" | grep -m 1 -o '^[[:alnum:]_]*')

    [ -n "${fpga_board-}" ] || \
       error "No FPGA board is selected in $select_file:" \
             "\n\n$(cat "$select_file")\n\n"
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
