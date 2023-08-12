. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/00_setup.source.bash"

cd ..

rm -rf run log.txt

if [ -n "${openlane_dir-}" ] ; then
    rm -rf "$openlane_dir/designs/$lab_name"
fi
