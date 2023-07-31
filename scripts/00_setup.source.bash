set -Eeuo pipefail  # See the meaning in scripts/README.md
#set -x  # Print each command

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

    if    [ -n "${QUARTUS_HOME-}" ]  \
       && [ -d "$QUARTUS_HOME/$intelfpga_install_dir" ]
    then
        intelfpga_install_parent_dir="$QUARTUS_HOME"
    fi

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        if [ -z "${intelfpga_install_parent_dir-}" ]
        then
            intelfpga_install_parent_dir="$HOME"
        fi

        quartus_bin_dir=bin

        if ! [ -d "$intelfpga_install_parent_dir/$intelfpga_install_dir" ]
        then
            intelfpga_install_parent_dir_first="$intelfpga_install_parent_dir"
            intelfpga_install_parent_dir=/opt
        fi

    elif  [ "$OSTYPE" = "cygwin"    ]  \
       || [ "$OSTYPE" = "msys"      ]
    then
        if [ -z "${intelfpga_install_parent_dir-}" ]
        then
            intelfpga_install_parent_dir=/c
        fi

        quartus_bin_dir=bin64

        if ! [ -d "$intelfpga_install_parent_dir/$intelfpga_install_dir" ]
        then
            intelfpga_install_parent_dir_first="$intelfpga_install_parent_dir"
            intelfpga_install_parent_dir=/d
        fi
    else
        error "this script does not support your OS / platform '$OSTYPE'"
    fi

    #-------------------------------------------------------------------------

    if ! [ -d "$intelfpga_install_parent_dir/$intelfpga_install_dir" ]
    then
        if [ -z "${intelfpga_install_parent_dir_first-}" ]
        then
            error "expected to find '$intelfpga_install_dir' directory"  \
                  "in '$intelfpga_install_parent_dir'."                  \
                  "'$intelfpga_install_dir' location can be set by the environment variable QUARTUS_HOME"
        else
            error "expected to find '$intelfpga_install_dir' directory"  \
                  "either in '$intelfpga_install_parent_dir_first'"      \
                  "or in '$intelfpga_install_parent_dir'."               \
                  "'$intelfpga_install_dir' location can be set by the environment variable QUARTUS_HOME"
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

        info "QUARTUS_ROOTDIR=${QUARTUS_ROOTDIR-}"
        info "PATH=${PATH-}"
        info "LD_LIBRARY_PATH=${LD_LIBRARY_PATH-}"
    fi

    #-------------------------------------------------------------------------

                   [ -d "$QUARTUS_ROOTDIR" ]  \
    || error "directory '$QUARTUS_ROOTDIR' expected"

                   [ -d "$QUARTUS_ROOTDIR/$quartus_bin_dir" ]  \
    || error "directory '$QUARTUS_ROOTDIR/$quartus_bin_dir' expected"

    #-------------------------------------------------------------------------

    # Workarounds for Quartus library problems
    # that are uncovered under RED OS from https://www.red-soft.ru

    if    ! [ -f /usr/lib64/libcrypt.so.1 ]  \
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
#   Gowin IDE setup
#
#-----------------------------------------------------------------------------

gowin_ide_setup ()
{
    echo "WIP: IDE setup for gowin chips"

    gowin_ide_setup_dir=/opt/gowin

    if [ ! -d $gowin_ide_setup_dir]
    then
        error "Gowin IDE not found in /opt/gowin"
    fi
    
    gowin_sh="$gowin_ide_setup_dir/IDE/bin/gw_sh"
}

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

    # We need relative paths here because Quartus under Windows
    # does not like /c/... full paths.

    # We don't need quotation marks around relative paths
    # because these particular relative paths
    # are expected to contain only alnums, underscores and slashes.

    rel_parent_dir=$(realpath --relative-to="$dir" "$parent_dir")
    rel_board_dir=$(realpath  --relative-to="$dir" "$board_dir")
    rel_lab_dir=$(realpath    --relative-to="$dir" "$lab_dir")

  
    case $fpga_board in 

    "c5gx" | "de0_cv" | "de10_lite" | "omdazz" | "rzrd" | "zeowaa")

        > "$dir/fpga_project.qpf"

        cat << EOF > "$dir/fpga_project.qsf"
set_global_assignment -name NUM_PARALLEL_PROCESSORS  4
set_global_assignment -name TOP_LEVEL_ENTITY         board_specific_top
set_global_assignment -name SDC_FILE                 $rel_board_dir/$fpga_board/board_specific.sdc

set_global_assignment -name SEARCH_PATH $rel_parent_dir
set_global_assignment -name SEARCH_PATH $rel_board_dir/$fpga_board
set_global_assignment -name SEARCH_PATH $rel_lab_dir/common

EOF

        find "$parent_dir" "$board_dir/$fpga_board" "$lab_dir/common"  \
            -type f -name '*.sv' -not -name tb.sv  \
            -printf "set_global_assignment -name SYSTEMVERILOG_FILE %f\n"  \
            >> "$dir/fpga_project.qsf"

        if [ -f "$parent_dir/extra_project_files.qsf" ] ; then
            cat "$parent_dir/extra_project_files.qsf" >> "$dir/fpga_project.qsf"
        fi

        cat "$board_dir/$fpga_board/board_specific.qsf" >> "$dir/fpga_project.qsf"
    ;;

    "tangprimer20k") 
    
        echo "WIP: project creation for gowin chips"

        #TODO: move gowin_ide_setup to common setup place
        gowin_ide_setup

        > "$dir/fpga_project.tcl"
        cat "$board_dir/$fpga_board/board_specific.tcl" >> "$dir/fpga_project.tcl"

        find "$parent_dir" \
            -type f -name '*.sv' -not -name tb.sv  \
            -printf "add_file -type verilog $parent_dir/%f\n" \
            >> "$dir/fpga_project.tcl"

        find "$board_dir/$fpga_board"  \
            -type f -name '*.sv' -not -name tb.sv  \
            -printf "add_file -type verilog $board_dir/$fpga_board/%f\n" \
            >> "$dir/fpga_project.tcl"

        find "$lab_dir/common"  \
            -type f -name '*.sv' -not -name tb.sv  \
            -printf "add_file -type verilog $lab_dir/common/%f\n" \
            >> "$dir/fpga_project.tcl"

        echo "run all" >> "$dir/fpga_project.tcl"
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

fpga_board_setup ()
{
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
            create_new_run_directories_for_fpga_synthesis
        fi
    fi

    if ! [[ " $available_fpga_boards " =~ " $fpga_board " ]] ; then
        # This error may happen if people mess with the selection file

        error "The selected FPGA board $fpga_board"  \
              "is not one of the available boards: $available_fpga_boards"
    fi
}

#-----------------------------------------------------------------------------
#
#   OpenLane setup and common routines
#
#-----------------------------------------------------------------------------

openlane_setup ()
{
    if ! [[ $script =~ asic ]] ; then
        return
    fi

    default_openlane_dir="$HOME/OpenLane"

    if   [ -n "${OPENLANE_ROOTDIR-}" ] && [ -d "${OPENLANE_ROOTDIR-}" ] ; then
        openlane_dir="$OPENLANE_ROOTDIR"
    elif [ -n "${OPENLANE_HOME-}" ] && [ -d "${OPENLANE_HOME-}" ] ; then
        openlane_dir="$OPENLANE_HOME"
    elif [ -d "$default_openlane_dir" ] ; then
        openlane_dir="$default_openlane_dir"
    else
        error "Cannot find OpenLane directory for ASIC synthesis and layout editor." \
              "By default it is expected at \"$default_openlane_dir\"," \
              "but its location can be set by the environment variable OPENLANE_ROOTDIR" \
              "or (second priority) OPENLANE_HOME"
    fi
}

#-----------------------------------------------------------------------------

run_openlane_layout_viewer ()
{
    if [ -z "${1-}" ] ; then
        LAYOUT_VIEWER_OPTION=
    else
        LAYOUT_VIEWER_OPTION="LAYOUT_VIEWER=$1"
    fi

    design_dir="$openlane_dir/designs/$lab_name"
    runs_dir="$design_dir/runs"

    [ -d "${runs_dir-}" ]  \
        || error "Cannot find OpenLane runs directory"

    last_run_dir=$(ls -d "$runs_dir"/RUN* | sort | tail -1)

    ! [ -z "${last_run_dir-}" ]  \
        || error "No RUN directory from the last run."  \
                 "You may need to run the ASIC synthesis script first."

    cd "$openlane_dir"

    run_dir_relative_to_open_lane_dir=$(realpath --relative-to="$openlane_dir" "$last_run_dir")

    make -f "$script_dir/asic/run_layout_viewer.mk" run_layout_viewer  \
      $LAYOUT_VIEWER_OPTION RUN_DIR_RELATIVE_TO_OPEN_LANE_DIR="$run_dir_relative_to_open_lane_dir"
}

#-----------------------------------------------------------------------------
#
#   Calling routines
#
#-----------------------------------------------------------------------------

is_command_available quartus  || intel_fpga_setup_quartus

if [ -z "${MGLS_LICENSE_FILE-}" ] ; then
    is_command_available vsim || intel_fpga_setup_questa
fi

is_command_available iverilog || icarus_verilog_setup

fpga_board_setup
openlane_setup
