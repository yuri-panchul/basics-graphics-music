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

    [ -d "$design_dir" ]  \
        || error "The OpenLane ASIC synthesis script"        \
                 "was not run for the design \"$lab_name\""

    runs_dir="$design_dir/runs"

    [ -d "$runs_dir" ]  \
        || error "Cannot find the OpenLane \"runs\" directory"            \
                 "inside \"$design_dir\"."                                \
                 "You probably need to re-run the ASIC synthesis script"  \
                 "for the design \"$lab_name\"."

    last_run_dir=$(ls -d "$runs_dir"/RUN* | sort | tail -1)

    ! [ -z "$last_run_dir" ]  \
        || error "No RUN directory from the last ASIC synthesis run."     \
                 "You probably need to re-run the ASIC synthesis script"  \
                 "for the design \"$lab_name\"."

    [ -d "$last_run_dir/results/signoff" ]  \
        || error "No \"results/signoff\" subdirectory inside"             \
                 "\"$last_run_dir\"."                                     \
                 "It indicates that the last ASIC synthesis run"          \
                 "for the design \"$lab_name\" failed."

    [ -n "$(ls -A "$last_run_dir/results/signoff")" ]  \
        || error "The \"$last_run_dir/results/signoff\" directory"        \
                 "is empty."                                              \
                 "It indicates that the last ASIC synthesis run"          \
                 "for the design \"$lab_name\" failed."

    cd "$openlane_dir"

    run_dir_relative_to_open_lane_dir=$(realpath --relative-to="$openlane_dir" "$last_run_dir")

    make -f "$script_dir/asic/run_layout_viewer.mk" run_layout_viewer  \
      $LAYOUT_VIEWER_OPTION RUN_DIR_RELATIVE_TO_OPEN_LANE_DIR="$run_dir_relative_to_open_lane_dir"
}
