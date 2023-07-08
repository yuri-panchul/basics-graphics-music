. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

design_dir="$openlane_dir/designs/$lab_name"

mkdir -p "$design_dir/src"

cp "$script_dir/asic/"*.tcl "$design_dir"

if [ -f ../asic_config.tcl ] ; then
    cp ../asic_config.tcl "$design_dir"/config.tcl
fi

cp ../*.sv* "$lab_dir/common"/*.sv* "$design_dir/src"

cd "$openlane_dir"
make quick_run QUICK_RUN_DESIGN=$lab_name |& tee "$log"
