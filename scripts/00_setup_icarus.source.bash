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

#-----------------------------------------------------------------------------

run_icarus_verilog ()
{
    is_command_available_or_error_and_install iverilog

    iverilog -g2005-sv \
         -I ..      -I "$lab_dir/common" \
            ../*.sv    "$lab_dir/common"/*.sv \
        |& tee "$log"

    vvp a.out |& tee "$log"

    if grep -m 1 ERROR "$log" ; then
        warning errors detected
    fi

    #-------------------------------------------------------------------------

    is_command_available_or_error_and_install gtkwave

    gtkwave_script=../gtkwave.tcl

    gtkwave_options=

    if [ -f $gtkwave_script ]; then
        gtkwave_options="--script $gtkwave_script"
    fi

    if    [ "$OSTYPE" = "linux-gnu" ]  \
       || [ "$OSTYPE" = "cygwin"    ]  \
       || [ "$OSTYPE" = "msys"      ]
    then
        gtkwave=gtkwave
    elif [ ${OSTYPE/[0-9]*/} = "darwin" ]
    # elif [[ "$OSTYPE" = "darwin"* ]]  # Alternative way
    then
        # For some reason the following way of opening the application
        # under Mac does not read the script file:
        #
        # open -a gtkwave dump.vcd --args --script $PWD/gtkwave.tcl
        #
        # This way works:

        gtkwave=/Applications/gtkwave.app/Contents/MacOS/gtkwave-bin
    else
        error 1 "don't know how to run GTKWave on your OS $OSTYPE"
    fi

    $gtkwave dump.vcd $gtkwave_options
}
