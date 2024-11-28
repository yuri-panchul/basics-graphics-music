#!/bin/sh

iverilog                                  \
    -g2005-sv                             \
    -D LOCAL_TB                           \
    -I ../include                         \
    -I ../import/preprocessed/cvw         \
    ../import/preprocessed/cvw/config.vh  \
    ../import/preprocessed/cvw/*.sv       \
    *.sv

vvp a.out
rm -rf a.out

#import/proprocessed/cvw/fcmp.sv
