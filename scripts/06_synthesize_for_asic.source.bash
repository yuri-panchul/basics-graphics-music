. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

design_dir="$openlane_dir/designs/$lab_name"

rm -rf "$design_dir"

mkdir -p "$design_dir/src"

cp "$script_dir/asic/"*.tcl "$design_dir"

if [ -f ../asic_config.tcl ] ; then
    cp ../asic_config.tcl "$design_dir"/config.tcl
fi

find "$parent_dir" "$lab_dir/common"  \
    -type f -name '*.sv*' -not -name tb.sv  \
        | xargs -I % cp %  "$design_dir/src"

cp ../*.sv "$lab_dir/common"/*.sv* "$design_dir/src"

if [ -f ../extra_asic_srcasic_config.tcl ] ; then
    cp ../asic_config.tcl "$design_dir"/config.tcl
fi

cd "$openlane_dir"
make quick_run QUICK_RUN_DESIGN=$lab_name |& tee "$log"
