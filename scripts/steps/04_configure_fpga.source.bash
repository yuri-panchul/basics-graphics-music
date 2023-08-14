[ -z "${setup_source_bash_already_run-}" ] && \
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

case $fpga_toolchain in
    quartus ) configure_fpga_quartus ;;
    gowin   ) configure_fpga_gowin   ;;
    *       ) error "Unsupported FPGA synthesis toolchain: $fpga_toolchain" ;;
esac
