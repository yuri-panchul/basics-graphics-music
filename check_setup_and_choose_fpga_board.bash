#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

cd $(dirname "$0")

force_removing_fpga_board_selection=1

. ./scripts/00_setup.source.bash
