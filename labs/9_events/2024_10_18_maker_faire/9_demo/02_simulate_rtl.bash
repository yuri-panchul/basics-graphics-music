#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

script=$(basename "$0")
source_script=${script/\.bash/.source_bash}
dir_source_script=../scripts/steps/$source_script

for i in {1..3}
do
    [ -f $dir_source_script ] && break
    dir_source_script=../$dir_source_script
done

if ! [ -f $dir_source_script ]; then
    printf "$script: cannot find \"$source_script\"\n" 1>&2
    exit 1
fi

dir_source_script=$(readlink -f $dir_source_script)
. "$dir_source_script"
