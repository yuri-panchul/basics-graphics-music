#!/bin/bash

make clean 
make -n code_demo.mem32 | tee ${0}.lst
