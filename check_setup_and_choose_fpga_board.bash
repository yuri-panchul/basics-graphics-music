#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

cd $(dirname "$0")

# Are you sure to remove the current FPGA board selection?

rm -rf fpga_board_selection

. ./scripts/00_setup.source.bash
