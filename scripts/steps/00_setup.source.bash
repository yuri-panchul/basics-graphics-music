set -Eeuo pipefail  # See the meaning in scripts/README.md
#set -x  # Print each command

setup_source_bash_already_run=1

#-----------------------------------------------------------------------------
#
#   Directory setup
#
#-----------------------------------------------------------------------------

package_dir=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/../..")
board_dir="$package_dir/boards"
lab_dir="$package_dir/labs"
script_dir="$package_dir/scripts"

#-----------------------------------------------------------------------------

script=$(basename "$0")
log="$PWD/log.txt"

if [[ $script =~ choose.*fpga_board ]]
then
    offer_to_create_a_new_fpga_board_select_file=1
else
    offer_to_create_a_new_fpga_board_select_file=0

    cd $(dirname "$0")
    mkdir -p run
    cd run
fi

lab_name=$(basename "$(readlink -f ..)")

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
        error "program $1${2-} is not in the path or cannot be run${3-}"
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
#   Tool setup:
#
#   Intel FPGA Quartus and Questa, licensed by Intel from Siemens EDA
#   Gowin IDE
#   Open Lane
#   Icarus Verilog
#
#-----------------------------------------------------------------------------

source "$script_dir/steps/00_setup_intel_fpga.source.bash"
source "$script_dir/steps/00_setup_gowin.source.bash"
source "$script_dir/steps/00_setup_open_lane.source.bash"
source "$script_dir/steps/00_setup_icarus.source.bash"

#-----------------------------------------------------------------------------
#
#   FPGA board setup
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

#-----------------------------------------------------------------------------

setup_run_directory_for_fpga_synthesis()
{
    dir="${1:-.}"
    parent_dir=$(readlink -f "$dir/..")

    rm -rf "$dir"/*

    case $fpga_toolchain in
    quartus)
        setup_run_directory_for_fpga_synthesis_quartus "$dir" "$parent_dir"
        ;;
    gowin)
        setup_run_directory_for_fpga_synthesis_gowin   "$dir" "$parent_dir"
        ;;
    *)
        error "Unsupported FPGA synthesis toolchain: $fpga_toolchain"
        ;;
    esac
}

#-----------------------------------------------------------------------------

create_new_run_directories_for_fpga_synthesis()
{
    $find_to_run "$lab_dir" -name '*synthesize_for_fpga.bash' \
        | while read file
    do
        dir=$(readlink -f "$(dirname "$file")/run")
        info "Setting up: \"$dir\""
        mkdir -p "$dir"
        setup_run_directory_for_fpga_synthesis $dir
    done
}

#-----------------------------------------------------------------------------

update_fpga_toolchain_var ()
{
    case $fpga_board in
        c5gx      | \
        de0_cv    | \
        de10_lite | \
        de2_115   | \
        omdazz    | \
        piswords6 | \
        rzrd      | \
        zeowaa    | \
        saylinx )
            fpga_toolchain=quartus
        ;;

        tangprimer20k)
            fpga_toolchain=gowin
        ;;

        *)
            fpga_toolchain=none
        ;;
    esac
}

#-----------------------------------------------------------------------------

fpga_board_setup ()
{
    fpga_toolchain=none

    if ! [[ $script =~ fpga ]] ; then
        return
    fi

    select_file="$package_dir/fpga_board_selection"

    if [ -f "$select_file" ]
    then
        fpga_board=$(grep -o '^[^#/-]*' "$select_file" | grep -m 1 -o '^[[:alnum:]_]*' || true)
        select_file_contents=$(cat "$select_file")

        if [ -z "${fpga_board-}" ] ; then
            offer_to_create_a_new_fpga_board_select_file=1
        fi

        if [ $offer_to_create_a_new_fpga_board_select_file = 1 ]
        then
            if [ -n "${fpga_board-}" ] ; then
               info "The current contents of \"$select_file:\""  \
                    "\n\n$select_file_contents"  \
                    "\n\nThe currently selected FPGA board: $fpga_board"
            else
               info "Currently no FPGA board is selected in \"$select_file:\""  \
                    "\n\n$select_file_contents\n"
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

            read -n 1 -r -p "Would you like to choose a new board and overwrite FPGA board selection file at \"$select_file\"? [y/n] "
            printf "\n"

            if ! [[ "$REPLY" =~ ^[Yy]$ ]] ; then
                info Exiting
                exit 0
            fi
        fi
    fi

    #-------------------------------------------------------------------------

    available_fpga_boards=$($find_to_run "$board_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tr "\n" " ")

    if    ! [ -f "$select_file" ]  \
       ||   [ $offer_to_create_a_new_fpga_board_select_file = 1 ]
    then
        info "Please select an FPGA board amoung the following supported:"
        PS3="Your choice (a number): "

        select fpga_board in $available_fpga_boards exit
        do
            if [ -z "${fpga_board-}" ] ; then
                info "Invalid FPGA board choice, please choose one of the listed numbers again"
                continue
            fi

            if [ $fpga_board == "exit" ] ; then
                info "FPGA board is not selected, please run the script again"
                exit 0
            fi

            info "FPGA board selected: $fpga_board"
            break
        done

        create_fpga_board_select_file

        read -n 1 -r -p "Would you like to create the new run directories for the synthesis of all labs in the package, based on your FPGA board selection? We recommend to do this if you plan to work with Quartus GUI rather than with the synthesis scripts. [y/n] "
        printf "\n"

        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            printf "\n"

            update_fpga_toolchain_var
            create_new_run_directories_for_fpga_synthesis
        fi
    fi

    if ! [[ " $available_fpga_boards " =~ " $fpga_board " ]] ; then
        # This error may happen if people mess with the selection file

        error "The selected FPGA board $fpga_board"  \
              "is not one of the available boards: $available_fpga_boards"
    fi

    #-------------------------------------------------------------------------

    update_fpga_toolchain_var
}

#-----------------------------------------------------------------------------
#
#   Calling routines
#
#-----------------------------------------------------------------------------

fpga_board_setup

case $fpga_toolchain in
    quartus)
        intel_fpga_setup_quartus

        if [ -z "${MGLS_LICENSE_FILE-}" ] ; then
            intel_fpga_setup_questa
        fi
    ;;

    gowin)
        gowin_ide_setup
    ;;
esac

openlane_setup
icarus_verilog_setup
