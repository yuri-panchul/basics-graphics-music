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
#   Intel FPGA Quartus
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
#   Intel FPGA Questa
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
#
#   Intel FPGA boards
#
#-----------------------------------------------------------------------------

