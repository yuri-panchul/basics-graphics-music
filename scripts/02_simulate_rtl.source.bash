. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

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

if [ -f $questa_script ] ; then
    run_questa
else
    run_icarus_verilog
fi
