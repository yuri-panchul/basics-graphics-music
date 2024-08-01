#!/bin/bash

#set -x

for d in * ; # de1 de0_cv de10_lite
do
  if ! [ -d $d ] ; then continue; fi
  cd $d
  f1=$(find . -name '*for_reference')
  f2=$(find . -name '*qsf')
  if [ -z "$f1" ] ; then cd .. ; continue; fi

  grep set_location_assignment $f1 | grep LED | sed 's/# *//g' | sed 's/ //g' | sort -u >z1
  grep set_location_assignment $f2 | grep LED | sed 's/# *//g' | sed 's/ //g' | sort -u >z2
  tkdiff z1 z2
  rm z1 z2
  cd ..
done

