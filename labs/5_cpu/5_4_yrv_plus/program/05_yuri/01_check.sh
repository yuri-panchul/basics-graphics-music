#!/bin/bash

make clean 
make -n check | tee ${0}.lst
