expected_source_script=00_setup.source.bash

if [ -z "$BASH_SOURCE" ]
then
    printf "script \"$0\" should be sourced from $expected_source_script\n" 1>&2
    exit 1
fi

this_script=$(basename "${BASH_SOURCE[0]}")
source_script=$(basename "${BASH_SOURCE[1]}")

if [ -z "$source_script" ]
then
    printf "script \"$this_script\" should be sourced from $expected_source_script\n" 1>&2
    return 1
fi

if [ "$source_script" != $expected_source_script ]
then
    printf "script \"$this_script\" should be sourced from \"$expected_source_script\", not \"$source_script\"\n" 1>&2
    exit 1
fi

#-----------------------------------------------------------------------------
#
#   Intel FPGA Quartus, formerly from Altera
#
#-----------------------------------------------------------------------------

intel_fpga_setup_quartus ()
{
    if is_command_available quartus ; then
        return  # Already set up
    fi

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
#   Intel FPGA version of Questa by Siemens EDA (former Mentor Graphics)
#
#-----------------------------------------------------------------------------

intel_fpga_setup_questa ()
{
    if is_command_available vsim ; then
        return  # Already set up
    fi

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

questa_script=../questa.tcl
[ "$OSTYPE" = "linux-gnu" ] && [ "$USER" = panchul ] && questa_script=../questa2.tcl

run_questa ()
{
    error_prefix="This example is supposed to be run with Questa simulator. However,"

       [ "$OSTYPE" = "linux-gnu" ]  \
    || [ "$OSTYPE" = "cygwin"    ]  \
    || [ "$OSTYPE" = "msys"      ]  \
    || error "$error_prefix this simulator does not run under OS / platform '$OSTYPE'"

    if [ -z "${LM_LICENSE_FILE-}" ] && ! [ -f "$MGLS_LICENSE_FILE" ]
    then
        warning "$error_prefix your variable LM_LICENSE_FILE is not set"  \
                "and the default license file '$MGLS_LICENSE_FILE'"       \
                "does not exist."                                         \
                "You may need to resolve the licensing issues."
    fi

    if ! is_command_available vsim
    then
        error "$error_prefix vsim executable is not available."  \
              "Have you installed the simulator, either"         \
              "together with Quartus package or separately?"
    fi

    if grep 'add wave' $questa_script ; then
        vsim_options=-gui
    else
        vsim_options=-c
    fi

    vsim $vsim_options -do $questa_script 2>&1
    cp transcript "$log"

    if [ -f coverage.ucdb ] ; then
        vcover report -details -html coverage.ucdb
    fi
}

#-----------------------------------------------------------------------------
#
#   Intel FPGA boards
#
#-----------------------------------------------------------------------------

setup_run_directory_for_fpga_synthesis_quartus ()
{
    dir="$1"
    main_src_dir="$2"

    #-------------------------------------------------------------------------

    # We need relative paths here because Quartus under Windows
    # does not like /c/... full paths.

    # We don't need quotation marks around relative paths
    # because these particular relative paths
    # are expected to contain only alnums, underscores and slashes.

    rel_main_src_dir=$(realpath --relative-to="$dir" "$main_src_dir")
    rel_board_dir=$(realpath    --relative-to="$dir" "$board_dir")
    rel_lab_dir=$(realpath      --relative-to="$dir" "$lab_dir")

    #-------------------------------------------------------------------------

    > "$dir/fpga_project.qpf"

    cat << EOF > "$dir/fpga_project.qsf"
set_global_assignment -name NUM_PARALLEL_PROCESSORS  4
set_global_assignment -name TOP_LEVEL_ENTITY         board_specific_top
set_global_assignment -name SDC_FILE                 $rel_board_dir/$fpga_board/board_specific.sdc

set_global_assignment -name SEARCH_PATH $rel_main_src_dir
set_global_assignment -name SEARCH_PATH $rel_board_dir/$fpga_board
set_global_assignment -name SEARCH_PATH $rel_lab_dir/common

EOF

    $find_to_run  \
        "$main_src_dir" "$board_dir/$fpga_board" "$lab_dir/common"  \
        -type f -name '*.sv' -not -name tb.sv  \
        -printf "set_global_assignment -name SYSTEMVERILOG_FILE %f\n"  \
        >> "$dir/fpga_project.qsf"

    if [ -f "$main_src_dir/extra_project_files.qsf" ] ; then
        cat "$main_src_dir/extra_project_files.qsf" >> "$dir/fpga_project.qsf"
    fi

    cat "$board_dir/$fpga_board/board_specific.qsf" >> "$dir/fpga_project.qsf"
}

#-----------------------------------------------------------------------------
#
#   Synthesis and configuration
#
#-----------------------------------------------------------------------------

synthesize_for_fpga_quartus ()
{
    is_command_available_or_error quartus_sh " from Intel FPGA Quartus Prime package"

    if ! quartus_sh --no_banner --flow compile fpga_project |& tee -a "$log"
    then
        grep -i -A 5 error "$log" 2>&1
        error "synthesis failed"
    fi
}

#-----------------------------------------------------------------------------

configure_fpga_quartus ()
{
    is_command_available_or_error quartus_pgm " from Intel FPGA Quartus Prime package"

    #-------------------------------------------------------------------------

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        rules_dir=/etc/udev/rules.d
        rules_file="$script_dir/fpga/90-intel-fpga.rules"

        if ! grep -q USB-Blaster $rules_dir/*
        then
            error "No rules for USB Blaster detected in $rules_dir."  \
                  "Please put it there and reboot: sudo cp $rules_file $rules_dir"
        fi

        killall jtagd 2>/dev/null || true
    fi

    #-------------------------------------------------------------------------

    quartus_pgm -l &> cable_list

    cable_name_1=$(set +o pipefail; grep "1) " cable_list | sed 's/.*1) //')
    cable_name_2=$(set +o pipefail; grep "2) " cable_list | sed 's/.*2) //')

    if [ -n "${cable_name_1-}" ]
    then
        if [ -n "${cable_name_2-}" ]
        then
            warning "more than one cable is connected:" \
                    "$cable_name_1 and $cable_name_2"
        fi

        info "using cable $cable_name_1"

        config_file_1=fpga_project.sof
        config_file_2=fpga_project.pof

        config_file=$config_file_1

        if ! [ -f $config_file ]
        then
            config_file=$config_file_2

            if ! [ -f $config_file ]
            then
                error "Neither $config_file_1 nor $config_file_2" \
                    "config file is available"
            fi
        fi

        quartus_pgm --no_banner -c "$cable_name_1" --mode=jtag -o "P;$config_file"
    else
        error "cannot detect a USB-Blaster cable connected" \
            "for $fpga_board FPGA board"
    fi

    rm cable_list
}
