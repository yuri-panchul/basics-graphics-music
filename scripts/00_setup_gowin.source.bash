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
            error "Gowin IDE not found in /opt/gowin"
        fi
    fi

    gowin_sh="$gowin_ide_setup_dir/IDE/bin/gw_sh"
}
