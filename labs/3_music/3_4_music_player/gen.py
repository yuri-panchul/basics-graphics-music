#!/usr/bin/env python3

from sys import argv
from math import sin, pi

freqs = {
    'C'  : 261.63,
    'Cs' : 277.18,
    'D'  : 293.66,
    'Ds' : 311.13,
    'E'  : 329.63,
    'F'  : 349.23,
    'Fs' : 369.99,
    'G'  : 392.00,
    'Gs' : 415.30,
    'A'  : 440.00,
    'As' : 466.16,
    'B'  : 493.88,
}

usage = f"usage:\n{argv[0]} [--freq freq_in_hz | --note C|Cs|D|Ds|E|F|Fs|G|Gs|A|As|B] bit_width sampling_rate_freq_in_hz volume_%"

if len(argv) != 6:
    exit(usage)

if argv[1] == '--freq':
    note = None
    F = float(argv[2])
elif argv[1] == '--note':
    note = argv[2]
    F = freqs[note]
else:
    exit(usage)

vol = int(argv[5])
Fs = int(argv[4])
w = int(argv[3])
A = (2**(w-1)-3276)*vol/100

N = int(Fs/(F*4)+0.5)
x_max = N

ts = [t for t in range(N+1)]
xs = [int(A*sin(pi*t/(N*2))+0.5) for t in ts]

print(f"// y(t) = sin((1/4)*2*pi*t*(F/Fs)), F={F}Hz, Fs={Fs}Hz, {w}-bit, Volume {vol}%")
print("")
if note is None:
    print("module table")
else:
    print(f"module table_{Fs}_{note}")
print("(")
print(f"    input        [ 8:0] x,")
print(f"    output       [ 8:0] x_max,")
print(f"    output logic [{w-1}:0] y")
print(");")
print("")
print(f"    assign x_max = {x_max};")
print("")
print("    always_comb")
print("        case (x)")
for t in ts:
    x = xs[t] & (2**w-1)
    print(f"        %2d: y = {w}'b{x:0{w}b};" % t)
print(f"        default: y = {w}'b0;")
print("        endcase")
print("")
print("endmodule")
print("")

#import matplotlib.pyplot as plt
#
#plt.plot(ts, xs, '.', lw=2)
#plt.grid(True)
#plt.show()
#
#installation
#python -m pip install -U pip
#python -m pip install -U matplotlib
