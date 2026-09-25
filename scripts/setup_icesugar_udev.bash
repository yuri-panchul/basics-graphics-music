#!/bin/bash
#
# Installs the udev rule required for flashing iCESugar-pro boards
# (iCELink / CMSIS-DAP programmer) without sudo.
#
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rules_src="$script_dir/fpga/99-icesugar-pro.rules"
rules_dst="/etc/udev/rules.d/99-icesugar-pro.rules"

if [ ! -f "$rules_src" ]; then
    echo "Error: $rules_src not found." >&2
    exit 1
fi

if [ -f "$rules_dst" ] && cmp -s "$rules_src" "$rules_dst"; then
    echo "udev rule for iCESugar-pro is already installed."
    exit 0
fi

echo "Installing udev rule for iCESugar-pro (iCELink)..."
sudo cp "$rules_src" "$rules_dst"
sudo udevadm control --reload-rules
sudo udevadm trigger

echo
echo "Done. Please unplug and replug the iCESugar-pro board."
echo "After that, the build script should be able to flash it without sudo."
