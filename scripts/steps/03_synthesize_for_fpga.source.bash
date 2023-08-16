. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

setup_run_directory_for_fpga_synthesis

#-----------------------------------------------------------------------------

> "$log"

if false && is_command_available iverilog
then
    iverilog -g2005-sv \
         -I ..      -I "$lab_dir/common" \
            ../*.sv    "$lab_dir/common"/*.sv \
        |& tee "$log"

    vvp a.out |& tee -a "$log"
fi

#-----------------------------------------------------------------------------

case $fpga_toolchain in
    quartus ) synthesize_for_fpga_quartus ;;
    gowin   ) synthesize_for_fpga_gowin   ;;
    *       ) error "Unsupported FPGA synthesis toolchain: $fpga_toolchain" ;;
esac

. "$script_dir/steps/04_configure_fpga.source.bash"
