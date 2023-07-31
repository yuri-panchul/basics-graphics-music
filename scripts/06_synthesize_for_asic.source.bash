. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

design_dir="$openlane_dir/designs/$lab_name"

mkdir -p  "$design_dir/src"
rm    -rf "$design_dir"/*.tcl "$design_dir/src"/*.sv*

cp "$script_dir/asic/"*.tcl "$design_dir"

if [ -f ../asic_config.tcl ] ; then
    cp ../asic_config.tcl "$design_dir"/config.tcl
fi

$find_to_run  \
    .. "$lab_dir/common"  \
    -type f -name '*.sv*' -not -name tb.sv  \
        | xargs -I % cp %  "$design_dir/src"

#-----------------------------------------------------------------------------

pushd "$openlane_dir" &> /dev/null
make quick_run QUICK_RUN_DESIGN=$lab_name |& tee "$log"
popd

#-----------------------------------------------------------------------------

runs_dir="$design_dir/runs"

[ -d "${runs_dir-}" ] || error "Cannot find OpenLane runs directory"

last_run_dir=$(ls -d "$runs_dir"/RUN* | sort | tail -1)

! [ -z "${last_run_dir-}" ] || error "No RUN directory"

cp "$log" 01_main.log

   cp "$last_run_dir"/results/synthesis/top.v               asic_02_synthesis.v                           \
&& cp "$last_run_dir"/results/placement/top.nl.v            asic_03_placement.nl.v                        \
&& cp "$last_run_dir"/results/routing/top.nl.v              asic_04_routing.nl.v                          \
&& cp "$last_run_dir"/results/final/verilog/gl/top.nl.v     asic_05_final_no_power_grid.nl.v              \
&& cp "$last_run_dir"/results/final/verilog/gl/top.v        asic_06_final.v                               \
&& cp "$last_run_dir"/reports/signoff/31-rcx_sta.max.rpt    asic_07_static_timing_analysis.sta.max.rpt    \
&& cp "$last_run_dir"/reports/signoff/31-rcx_sta.min.rpt    asic_08_static_timing_analysis.sta.min.rpt    \
&& cp "$last_run_dir"/reports/signoff/31-rcx_sta.power.rpt  asic_09_static_timing_analysis.sta.power.rpt  \
&& cp "$last_run_dir"/results/signoff/top.lef               asic_10_library_exchange_format.lef           \
&& cp "$last_run_dir"/results/signoff/top.mag               asic_11_magic.mag                             \
&& cp "$last_run_dir"/results/signoff/top.sdf               asic_12_standard_delay_format.sdf             \
|| error "Cannot copy something"

exit 0

   cp "$last_run_dir"/results/synthesis/top.v                   asic_02_synthesis.v    \
&& cp "$last_run_dir"/results/placement/top.resized.v           asic_03_placement.v    \
&& cp "$last_run_dir"/results/cts/top.resized.v                 asic_04_cts.v          \
&& cp "$last_run_dir"/results/routing/top.resized.v             asic_05_routing.v      \
&& cp "$last_run_dir"/results/final/verilog/gl/top.v            asic_06_final.v        \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.rpt        asic_07_mca_sta.rpt    \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.area.rpt   asic_08_mca_area.rpt   \
&& cp "$last_run_dir"/reports/signoff/29-rcx_mca_sta.power.rpt  asic_09_mca_power.rpt  \
&& cp "$last_run_dir"/results/signoff/top.mag                   asic_10_magic.mag      \
|| error "Cannot copy something"
