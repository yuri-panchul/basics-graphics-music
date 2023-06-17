scripts_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
. "$scripts_dir/00_setup.source.bash"

> top.qpf
cp ../*.qsf .

#-----------------------------------------------------------------------------

> "$log"

if false && is_command_available iverilog
then
    iverilog -g2005-sv ../*.sv 2>&1 | tee -a "$log"
    vvp a.out 2>&1 | tee -a "$log"
fi

#-----------------------------------------------------------------------------

is_command_available_or_error quartus_sh " from Intel FPGA Quartus Prime package"

if ! quartus_sh --no_banner --flow compile top 2>&1 | tee -a "$log"
then
    grep -i -A 5 error "$log" 2>&1
    error "synthesis failed"
fi

. "$scripts_dir/04_configure_fpga.source.bash"
