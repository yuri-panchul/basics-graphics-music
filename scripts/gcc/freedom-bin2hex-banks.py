# Copyright 2018 SiFive, Inc
# SPDX-License-Identifier: Apache-2.0

import argparse
import sys
import os

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


def convert_to_banks(bit_width, infile, base_filename):
    """Convert binary file to separate bank files for byte-addressable memory"""
    byte_width = bit_width // 8
    
    if byte_width != 4:
        sys.exit("This script currently only supports 32-bit (4-byte) width for bank splitting.")
    
    # Get directory and filename without extension
    dir_name = os.path.dirname(base_filename) or '.'
    file_base = os.path.basename(base_filename)
    name_without_ext, ext = os.path.splitext(file_base)
    
    # Open four bank files with names like: program_mem32_bank0.mem8
    bank_files = []
    for i in range(4):
        bank_filename = f"{name_without_ext}_bank{i}.mem8"
        filepath = os.path.join(dir_name, bank_filename)
        bank_files.append(open(filepath, 'w'))
    
    try:
        if sys.version_info >= (3, 0):
            for row in grouper(infile.read(), byte_width, fillvalue=0):
                # Write each byte to its corresponding bank file
                for bank_idx, byte_val in enumerate(row):
                    bank_files[bank_idx].write('{:02x}\n'.format(byte_val))
        else:
            for row in grouper(infile.read(), byte_width, fillvalue='\x00'):
                # Write each byte to its corresponding bank file
                for bank_idx, byte_val in enumerate(row):
                    bank_files[bank_idx].write('{:02x}\n'.format(ord(byte_val)))
    finally:
        # Close all bank files
        for f in bank_files:
            f.close()
    
    print(f"Bank files created:")
    for i in range(4):
        bank_filename = f"{name_without_ext}_bank{i}.mem8"
        print(f"  {os.path.join(dir_name, bank_filename)}")


def convert(bit_width, infile, outfile):
    """Convert binary file to single hex file"""
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
                    'verilog via $readmemh(). Always creates main hex file. '
                    'Use --banks to also create separate bank files.'
    )
    
    parser.add_argument('--banks', '-b',
                        action='store_true',
                        help='Also split into separate bank files')
    
    if sys.version_info >= (3, 0):
        parser.add_argument('infile',
                            type=argparse.FileType('rb'),
                            help='Input binary file')
    else:
        parser.add_argument('infile',
                            type=argparse.FileType('rb'),
                            help='Input binary file')
    
    parser.add_argument('basename',
                        nargs='?',
                        default=None,
                        help='Base name for output files (optional, defaults to input filename)')
    
    parser.add_argument('--bit-width', '-w',
                        type=int,
                        required=True,
                        help='How many bits per row.')
    
    args = parser.parse_args()

    if args.bit_width % 8 != 0:
        sys.exit("Cannot handle non-multiple-of-8 bit width yet.")
    
    # Use provided basename or fall back to input filename
    base_filename = args.basename if args.basename else args.infile.name
    
    # Get directory and filename without extension for main file
    dir_name = os.path.dirname(base_filename) or '.'
    file_base = os.path.basename(base_filename)
    name_without_ext, ext = os.path.splitext(file_base)
    main_hex_filename = f"{name_without_ext}{ext if ext else '.hex'}"
    main_hex_path = os.path.join(dir_name, main_hex_filename)
    
    # Always create main hex file
    print(f"Creating main hex file: {main_hex_path}")
    with open(main_hex_path, 'w') as outfile:
        # Need to re-read the file, so close and reopen
        args.infile.close()
        args.infile = open(args.infile.name, 'rb')
        convert(args.bit_width, args.infile, outfile)
    
    # Create bank files if requested
    if args.banks:
        if args.bit_width != 32:
            sys.exit("Bank mode currently only supports 32-bit width.")
        
        # Re-open input file for bank conversion
        args.infile.close()
        args.infile = open(args.infile.name, 'rb')
        convert_to_banks(args.bit_width, args.infile, base_filename)
    
    args.infile.close()


if __name__ == '__main__':
    main()