#!/usr/bin/env bash

PY3=python3
$PY3 --version || PY3=python

WIDTH=${1:-16}
VOLUME=${2:-100}
SAMPLRATE[1]=${3:-48828}
SAMPLRATE[2]=${4:-64453}
SAMPLRATE[3]=${5:-52734}
SAMPLRATE[4]=${6}
SAMPLRATE[5]=${7}
SAMPLRATE[6]=${8}
SAMPLRATE[7]=${9}

rm -f tone_table.svh

for sampling_rate in ${SAMPLRATE[@]}; do
for note in C Cs D Ds E F Fs G Gs A As B; do
    echo "Generating 1/4 sinus table for $sampling_rate Hz, $note, $WIDTH-bit, Volume $VOLUME% ..."
    $PY3 gen.py --note $note $WIDTH $sampling_rate $VOLUME >> tone_table.svh
done
done
