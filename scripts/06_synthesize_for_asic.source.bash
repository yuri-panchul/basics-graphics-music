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

                                                                   # 01_main.log
                                                                   # 02_main_violation.log
                                                                   # 09_mca_sta_violation.rpt
   cp "$last_run_dir"/results/synthesis/snail_moore_fsm.v          03_synthesis.v    \
&& cp "$last_run_dir"/results/placement/snail_moore_fsm.resized.v  04_placement.v    \
&& cp "$last_run_dir"/results/cts/snail_moore_fsm.resized.v        05_cts.v          \
&& cp "$last_run_dir"/results/routing/snail_moore_fsm.resized.v    06_routing.v      \
&& cp "$last_run_dir"/results/final/verilog/gl/snail_moore_fsm.v   07_final.v        \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.rpt           08_mca_sta.rpt    \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.area.rpt      10_mca_area.rpt   \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.power.rpt     11_mca_power.rpt  \
&& cp "$last_run_dir"/results/signoff/snail_moore_fsm.mag          12_magic.mag      \
|| error "Cannot copy something"
