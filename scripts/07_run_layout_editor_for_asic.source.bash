. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

cd "$openlane_dir"
make -f "$script_dir/asic/run_layout_editor.mk" run_layout_editor
