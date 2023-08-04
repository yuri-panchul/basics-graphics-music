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

icarus_verilog_setup ()
{
    if is_command_available iverilog ; then
        return  # Already set up
    fi

    alt_icarus_install_path="$HOME/install/iverilog"

    if [ -d "$alt_icarus_install_path" ]
    then
        export PATH="${PATH:+$PATH:}$alt_icarus_install_path/bin"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$alt_icarus_install_path/lib"
    fi
}
