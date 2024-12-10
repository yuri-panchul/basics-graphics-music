#!/usr/bin/bash

PY3=python3
$PY3 --version || PY3=python

WIDTH=${1:-16}

VOLUME=${2:-100}

rm -f tone_table.svh

sampling_rate=48828
for note in C Cs D Ds E F Fs G Gs A As B; do
    echo "Generating 1/4 sin table for $sampling_rate Hz, $note, $WIDTH-bit, Volume $VOLUME% ..."
    $PY3 gen.py --note $note $WIDTH $sampling_rate $VOLUME>> tone_table.svh
done

sampling_rate=64453
for note in C Cs D Ds E F Fs G Gs A As B; do
    echo "Generating 1/4 sin table for $sampling_rate Hz, $note, $WIDTH-bit, Volume $VOLUME% ..."
    $PY3 gen.py --note $note $WIDTH $sampling_rate $VOLUME>> tone_table.svh
done

sampling_rate=52734
for note in C Cs D Ds E F Fs G Gs A As B; do
    echo "Generating 1/4 sin table for $sampling_rate Hz, $note, $WIDTH-bit, Volume $VOLUME% ..."
    $PY3 gen.py --note $note $WIDTH $sampling_rate $VOLUME>> tone_table.svh
done