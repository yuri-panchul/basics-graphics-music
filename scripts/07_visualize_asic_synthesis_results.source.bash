. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

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

# make -f "$script_dir/asic/run_layout_editor.mk"   run_layout_editor

  make -f "$script_dir/asic/run_openroad_viewer.mk" run_openroad_viewer  \
      RUN_DIR_RELATIVE_TO_OPEN_LANE_DIR="$run_dir_relative_to_open_lane_dir"
