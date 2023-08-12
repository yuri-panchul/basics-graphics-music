. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

if [ -f $questa_script ] ; then
    run_questa
else
    run_icarus_verilog
fi
