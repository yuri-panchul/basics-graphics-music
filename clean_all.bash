#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

cd $(dirname "$0")
. ./scripts/steps/01_clean_all.source_bash
