#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

PY3=python3
$PY3 --version &> /dev/null || PY3=python

WIDTH=${1:-16}
VOLUME=${2:-100}

SAMPLING_RATE[1]=${3:-48828}
SAMPLING_RATE[2]=${4:-64453}
SAMPLING_RATE[3]=${5:-52734}
# Add more frequencies if needed

rm -f tone_table.svh

for sampling_rate in ${SAMPLING_RATE[@]}
do
    for note in C Cs D Ds E F Fs G Gs A As B
    do
        echo "Generating 1/4 sinus table for $sampling_rate Hz, $note, $WIDTH-bit, Volume $VOLUME% ..."
        $PY3 gen.py --note $note $WIDTH $sampling_rate $VOLUME >> tone_table.svh
    done
done
