#!/bin/sh

set -x

sed s/lab_top/lab_top_3_1_note_recognizer/g  ../3_1_note_recognizer/lab_top.sv  > lab_top_3_1_note_recognizer.sv
sed s/lab_top/lab_top_3_3_note_synthesizer/g ../3_3_note_synthesizer/lab_top.sv > lab_top_3_3_note_synthesizer.sv

cp ../3_3_note_synthesizer/tone*.sv* .
