#!/usr/bin/env bash

iverilog -g2005-sv    \
    -D INTEL_VERSION   my_module.v  testbench.v           \
    2>&1 | tee "log.txt"

vvp a.out 2>&1 | tee "log.txt"


