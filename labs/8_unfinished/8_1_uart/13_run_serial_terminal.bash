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
    #sudo minicom -D /dev/ttyUSB0 

    if [ -e uart.conf ]
    then

        dev=$(<uart.conf)
        echo $dev

        dev_grp=$(stat -c "%G" $dev)
        [ -n "${dev_grp-}" ] || error "Cannot determine the groups that owns $dev"

        if ! id -nG | grep -qw $dev_grp
        then
            echo
            echo "User \"$USER\" is not in \"$dev_grp\" group."  \
                "Run: \"sudo usermod -a -G $dev_grp $USER\","   \
                "then reboot and try again."                    \
                "(On some systems it is sufficient"             \
                "to logout and login instead of the reboot)."
            echo
            exit
        else
            echo run minicom
            echo "minicom -D $dev &"
            minicom -D $dev

        fi


    else
        echo "Create file uart.conf and write the tty device name"
        echo "Your system has UART:"
        ls -1 /dev/ttyUSB*
        echo 
        echo "Create file uart.conf: echo /dev/ttyUSBx > uart.conf"
        echo "instead /dev/ttyUSBx set your device"

    fi
fi
