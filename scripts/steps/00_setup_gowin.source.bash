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
        gowin_ide_setup_dir="$HOME/gowin"

        if ! [ -d $gowin_ide_setup_dir ]
        then
            error "Gowin IDE not found in /opt/gowin or \"$HOME/gowin\" \n You can download Gowin EDA here: https://www.gowinsemi.com/en/support/download_eda/"
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

    echo "add_file -type cst $board_dir/$fpga_board/board_specific.cst" >> "$dir/fpga_project.tcl"
    echo "add_file -type sdc $board_dir/$fpga_board/board_specific.sdc" >> "$dir/fpga_project.tcl"
    echo "run all" >> "$dir/fpga_project.tcl"
}

#-----------------------------------------------------------------------------

synthesize_for_fpga_gowin ()
{
    is_command_available_or_error "$gowin_sh" " from GoWin IDE package"
    "$gowin_sh" fpga_project.tcl
}

#-----------------------------------------------------------------------------

configure_fpga_gowin ()
{
    is_command_available_or_error openFPGALoader " tool openFPGALoader is not installed on system\n You can download openFPGALoader here: https://trabucayre.github.io/openFPGALoader/guide/install.html"

    #-------------------------------------------------------------------------

    if [ "$OSTYPE" = "linux-gnu" ]
    then
        rules_dir=/etc/udev/rules.d
        rules_file="$script_dir/fpga/91-sipeed.rules"

        if ! grep -q 'ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010"' $rules_dir/*
        then
            error "No rules for Sipeed FPGA loader detected in $rules_dir."  \
                  "Please put it there and reboot: sudo cp $rules_file $rules_dir"
        fi

        killall jtagd 2>/dev/null || true
    fi

    #-------------------------------------------------------------------------

    openFPGALoader -b $fpga_board impl/pnr/fpga_project.fs
}
