. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

design_dir="$openlane_dir/designs/$lab_name"

mkdir -p  "$design_dir/src"
rm    -rf "$design_dir"/*.tcl "$design_dir/src"/*.sv*

cp "$script_dir/asic/"*.tcl "$design_dir"

if [ -f ../asic_config.tcl ] ; then
    cp ../asic_config.tcl "$design_dir"/config.tcl
fi

find .. "$lab_dir/common"  \
    -type f -name '*.sv*' -not -name tb.sv  \
        | xargs -I % cp %  "$design_dir/src"

#-----------------------------------------------------------------------------

cd "$openlane_dir"
make quick_run QUICK_RUN_DESIGN=$lab_name |& tee "$log"

#-----------------------------------------------------------------------------

runs_dir="$design_dir/runs"

[ -d "${runs_dir-}" ] || error "Cannot find OpenLane runs directory"

last_run_dir=$(ls -d "$runs_dir"/RUN* | sort | tail -1)

! [ -z "${last_run_dir-}" ] || error "No RUN directory"

cp "$log" 01_main.log

   cp "$last_run_dir"/results/synthesis/top.v                   02_synthesis.v    \
&& cp "$last_run_dir"/results/placement/top.resized.v           03_placement.v    \
&& cp "$last_run_dir"/results/cts/top.resized.v                 04_cts.v          \
&& cp "$last_run_dir"/results/routing/top.resized.v             05_routing.v      \
&& cp "$last_run_dir"/results/final/verilog/gl/top.v            06_final.v        \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.rpt        07_mca_sta.rpt    \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.area.rpt   08_mca_area.rpt   \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.power.rpt  09_mca_power.rpt  \
&& cp "$last_run_dir"/results/signoff/top.mag                   10_magic.mag      \
|| error "Cannot copy something"
