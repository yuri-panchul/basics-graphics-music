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

gowin_ide_setup ()
{
    gowin_ide_setup_dir=/opt/gowin

    if ! [ -d $gowin_ide_setup_dir ]
    then
        gowin_ide_setup_dir="$HOME"

        if ! [ -d $gowin_ide_setup_dir ]
        then
            error "Gowin IDE not found in /opt/gowin or \"$HOME\""
        fi
    fi

    gowin_sh="$gowin_ide_setup_dir/IDE/bin/gw_sh"
}

#-----------------------------------------------------------------------------

setup_run_directory_for_fpga_synthesis_gowin ()
{
    dir="$1"
    main_src_dir="$2"

    > "$dir/fpga_project.tcl"
    cat "$board_dir/$fpga_board/board_specific.tcl" >> "$dir/fpga_project.tcl"

    for verilog_src_dir in  \
        "$main_src_dir"  \
        "$board_dir/$fpga_board"  \
        "$lab_dir/common"
    do
        $find_to_run  \
            "$verilog_src_dir"  \
            -type f -name '*.sv' -not -name tb.sv  \
            -printf "add_file -type verilog %p\n" \
            >> "$dir/fpga_project.tcl"
    done

    echo "run all" >> "$dir/fpga_project.tcl"
}
