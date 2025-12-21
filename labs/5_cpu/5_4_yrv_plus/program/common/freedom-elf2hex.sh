#!/bin/bash

unset bit_width
unset input
unset output
while [[ "$1" != "" ]]
do
    case "$1" in
    -h | --help) echo "$0 [-h, --help] --bit-width BIT_WIDTH --input INPUT.ELF [--output OUTPUT.HEX]" >&2; exit 0;;
    -w | --bit-width) bit_width="$2"; shift 2;;
    --input) input="$2"; shift 2;;
    --output) output="$2"; shift 2;;
    *) echo "$0: unknown argument $1">&2; exit 1;;
    esac
done
   
if [[ "$bit_width" == "" ]]
then
    echo "$0 [-h] --bit-width BIT_WIDTH --input INPUT.ELF [--output OUTPUT.HEX]" >&2
    exit 1
fi

if [[ "$input" == "" ]]
then
    echo "$0 [-h] --bit-width BIT_WIDTH --input INPUT.ELF [--output OUTPUT.HEX]" >&2
    exit 1
fi

if [[ "$objcopy" == "" ]]
then
    echo "$0: could not find objcopy"
    exit 1
fi

temp="$(mktemp -d)"
trap "rm -rf $temp" EXIT

"$objcopy" "$input" -O binary "$temp"/output.bin
if [[ "$output" == "" ]]
then
    "$bin2hex" -w "$bit_width" "$temp"/output.bin
else
    "$bin2hex" -w "$bit_width" "$temp"/output.bin "$output"
fi
