#!/usr/bin/env bash

#  set -e           - Exit immediately if a command exits with a non-zero
#                     status.  Note that failing commands in a conditional
#                     statement will not cause an immediate exit.
#
#  set -o pipefail  - Sets the pipeline exit code to zero only if all
#                     commands of the pipeline exit successfully.
#
#  set -u           - Causes the bash shell to treat unset variables as an
#                     error and exit immediately.
#
#  set -x           - Causes bash to print each command before executing it.
#
#  set -E           - Improves handling ERR signals


set -Eeuo pipefail
# set -x  # Print each command

#-----------------------------------------------------------------------------

script_path="$0"
script=$(basename "$script_path")

#-----------------------------------------------------------------------------

info ()
{
    printf "\n$script: $*\n" 1>&2
}

error ()
{
    info ERROR: $*
    exit 1
}

#-----------------------------------------------------------------------------

[ "$EUID" -eq 0 ] || \
    error "This script is supposed to be run under root." \
          "\nPlease run either:" \
          "\n    su -" \
          "\n    $script_path" \
          "\nor:" \
          "\n    sudo $script_path"

#-----------------------------------------------------------------------------

is_command_available_or_error ()
{
    command -v $1 &> /dev/null || \
        error "program $1$ is not in the path or cannot be run"
}

is_command_available_or_error partprobe

#-----------------------------------------------------------------------------

drive_image=$(find -maxdepth 1 -name '*.img' -type f -printf '%f\n')

[ -n "$drive_image" ] \
    || error "No files with .img extension in the current directory"

[ $(wc -l <<< "$drive_image") = 1 ]  \
    || error "Multiple files with .img extension in the current directory: $drive_image"

info "Using file \"$drive_image\" in the current directory as SSD image"

#-----------------------------------------------------------------------------

avail_drives=$(ls /dev/sd[a-z])

info "Please select an SSD you want to ovewrite"
PS3="Your choice (a number): "

select drive in $avail_drives exit
do
    if [ -z "${drive-}" ] ; then
        info "Invalid SSD choice, please choose one of the listed numbers again"
        continue
    fi

    if [ $drive == "exit" ] ; then
        info "SSD is not selected, please run the script again"
        exit 0
    fi

    info "SSD selected: $drive"
    break
done

#-----------------------------------------------------------------------------

mounted=$(grep -o "^$drive" /proc/mounts || true)

[ -z "$mounted" ] \
    || error "$drive is mounted. Please unmount and rerun the script."

#-----------------------------------------------------------------------------

info "Checking partitions before the operations:"
(set -x; partprobe -d -s $drive || true)

#-----------------------------------------------------------------------------

seek_value=$((($(blockdev --getsize64 $drive)-4096)/4096))
info "Seek value to erase the second GPT: $seek_value"

#-----------------------------------------------------------------------------

# read:
#
# -p prompt output the string PROMPT without a trailing newline before
#           attempting to read
#
# -r        do not allow backslashes to escape any characters

info "\nAre you absolutely positively sure"                           \
     "\nyou want to erase your SSD,"                                  \
     "\ndestroy all its partition tables"                             \
     "\nand write a new drive image from the file \"$drive_image\"?"  \

read -r -p "Type \"I SWEAR!\" : "

if [ "$REPLY" != "I SWEAR!" ] ; then
    info "You typed \"$REPLY\". Exiting."
    exit 0
fi

#-----------------------------------------------------------------------------

info "Erasing the backup GPT. If you see an error it is normal:"
(set -x; dd if=/dev/zero of=$drive bs=4096 seek=$seek_value) || true

info "Erasing the main GPT:"
(set -x; dd if=/dev/zero of=$drive bs=4096 seek=0 count=1) \
    || error "Something is wrong"

info "Now all the partition tables should be erased:"
(set -x; partprobe -d -s $drive) || true

info "Finally, the main copying:"
(set -x; dd if="$drive_image" of=$drive bs=1M status=progress && sync) \
    || error "Something is wrong"

info "Success, $drive_image is on $drive"
