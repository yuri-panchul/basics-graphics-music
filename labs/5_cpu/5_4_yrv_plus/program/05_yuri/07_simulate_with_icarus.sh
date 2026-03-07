#!/bin/bash

make clean 
make -n icarus gtkwave | tee ${0}.lst
