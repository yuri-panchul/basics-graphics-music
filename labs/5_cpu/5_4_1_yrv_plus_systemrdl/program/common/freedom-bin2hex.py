# Copyright 2018 SiFive, Inc
# SPDX-License-Identifier: Apache-2.0

import argparse
import sys

try:
# Python 3
    from itertools import zip_longest
except ImportError:
# Python 2
    from itertools import izip_longest as zip_longest


# Copied from https://docs.python.org/3/library/itertools.html
def grouper(iterable, n, fillvalue=None):
    """Collect data into fixed-length chunks or blocks"""
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)


def convert(bit_width, infile, outfile):
    byte_width = bit_width // 8
    if sys.version_info >= (3, 0):
        for row in grouper(infile.read(), byte_width, fillvalue=0):
            # Reverse because in Verilog most-significant bit of vectors is first.
            hex_row = ''.join('{:02x}'.format(b) for b in reversed(row))
            outfile.write(hex_row + '\n')
    else:
        for row in grouper(infile.read(), byte_width, fillvalue='\x00'):
            # Reverse because in Verilog most-significant bit of vectors is first.
            hex_row = ''.join('{:02x}'.format(ord(b)) for b in reversed(row))
            outfile.write(hex_row + '\n')


def main():
    parser = argparse.ArgumentParser(
        description='Convert a binary file to a format that can be read in '
                    'verilog via $readmemh(). By default read from stdin '
                    'and write to stdout.'
    )
    if sys.version_info >= (3, 0):
        parser.add_argument('infile',
                            nargs='?',
                            type=argparse.FileType('rb'),
                            default=sys.stdin.buffer)
    else:
        parser.add_argument('infile',
                            nargs='?',
                            type=argparse.FileType('rb'),
                            default=sys.stdin)
    parser.add_argument('outfile',
                        nargs='?',
                        type=argparse.FileType('w'),
                        default=sys.stdout)
    parser.add_argument('--bit-width', '-w',
                        type=int,
                        required=True,
                        help='How many bits per row.')
    args = parser.parse_args()

    if args.bit_width % 8 != 0:
        sys.exit("Cannot handle non-multiple-of-8 bit width yet.")
    convert(args.bit_width, args.infile, args.outfile)


if __name__ == '__main__':
    main()
