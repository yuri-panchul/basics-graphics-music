#!/usr/bin/bash

WIDTH=${1:-16}

rm -f tone_table.svh

for note in C Cs D Ds E F Fs G Gs A As B; do
    echo "Generating LUT for $note, $WIDTH-bit..."
    python gen.py --note $note $WIDTH >> tone_table.svh
done

