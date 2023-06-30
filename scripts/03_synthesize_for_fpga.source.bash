. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

> fpga_top.qpf
cp "$board_dir"/*.{qsf,sdc} .
cp "$board_dir"/$fpga_board/*.{qsf,sdc} .

#-----------------------------------------------------------------------------

> "$log"

if false && is_command_available iverilog
then
    iverilog -g2005-sv                       \
      -I ..      -I ../../../../common       \
         ../*.sv    ../../../../common/*.sv  \
      2>&1 | tee "$log"

    vvp a.out 2>&1 | tee -a "$log"
fi

#-----------------------------------------------------------------------------

is_command_available_or_error quartus_sh " from Intel FPGA Quartus Prime package"

if ! quartus_sh --no_banner --flow compile fpga_top 2>&1 | tee -a "$log"
then
    grep -i -A 5 error "$log" 2>&1
    error "synthesis failed"
fi

. "$script_dir/04_configure_fpga.source.bash"
