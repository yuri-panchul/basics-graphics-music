#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md

script=$(basename "$0")
source_script=${script/\.bash/.source_bash}
dir_source_script=../scripts/steps/$source_script

echo $script
echo $source_script
echo $dir_source_script

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
. "$dir_source_script" &

if    [ "$OSTYPE" = "msys" ]  
then
    # COM_BOARD is session name
    # The first time you run it, a configuration window will be displayed. 
    # Please select the  mode "Serial", serial port number  which the board is connected, 
    # serial mode 115200, 8N1, flow control "None" and save the session with the name "COM_BOARD"
    # The port number can be determined through the device manager
    putty -load COM_BOARD &
else
    # change device name /dev/ttyUSB0 for actual device in your system
    # Please set serial mode 115200, 8N1, flow control "None" and save the session as default
    sudo minicom -D /dev/ttyUSB0 
fi
