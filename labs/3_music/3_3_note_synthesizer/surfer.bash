#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

surfer ./run/dump.vcd --command-file surfer.scr
