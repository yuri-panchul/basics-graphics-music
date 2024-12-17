#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

echo "copy files from support/step_1 to current directory"

cp support/step_1/* .

echo "complete"
