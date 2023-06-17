. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"
cd ..
rm -rf run log.txt log_tb.txt log_tb_fpga_top.txt log_[0-9]*.txt
