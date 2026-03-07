#!/bin/bash

make clean 
make -n final.elf | tee ${0}.lst
