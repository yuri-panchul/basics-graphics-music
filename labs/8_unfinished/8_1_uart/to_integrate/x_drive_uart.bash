#!/usr/bin/env bash

. ./x_setup.bash

# id
#
# -G, --groups  print all group IDs
# -n, --name    print a name instead of a number, for -ugG
#
# grep
#
# -w, --word-regexp      match only whole words
# -q, --quiet, --silent  suppress all normal output

gr=dialout

if ! id -nG | grep -qw $gr
then
  error 1 User \"$USER\" is not in \"$gr\" group. \
     Run: \"sudo usermod -a -G $gr $USER\", \
     then logout, login and try again.
fi

dev=/dev/ttyUSB0

guarded stty -F $dev raw speed 115200 -crtscts cs8 -parenb -cstopb &> /dev/null
guarded cat > $dev
