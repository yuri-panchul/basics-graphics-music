#!/bin/bash

make clean 
make -n modelsim | tee ${0}.lst
