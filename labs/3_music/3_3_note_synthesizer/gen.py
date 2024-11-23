#!/usr/bin/python3

from sys import argv
from math import sin, pi, floor

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

Fs = 96000
usage = f"usage:\n{argv[0]} [--freq freq_in_hz | --note C|Cs|D|Ds|E|F|Fs|G|Gs|A|As|B] bit_width"


if len(argv) != 4:
    exit(usage)

if argv[1] == '--freq':
    note = None
    F = float(argv[2])
elif argv[1] == '--note':
    note = argv[2]
    F = freqs[note]
else:
    exit(usage)

w = int(argv[3])
A = 2**(w - 1) - 1

N = floor(Fs / F)
x_max = N - 1
x_width = x_max.bit_length()
y_width = w

ts = [t for t in range(N)]
xs = [round(A * sin(2 * pi * t / N)) for t in ts]

print("// y(t) = sin(2*pi*F*t), F={0}Hz, Fs={1}Hz, {2}-bit".format(F, Fs, w))
print("")
if note is None:
    print("module lut")
else:
    print(f"module lut_{note}")
print("(")
print(f"    input        [ 8:0] x,")
print(f"    output       [ 8:0] x_max,")
print(f"    output logic [15:0] y")
print(");")
print("")
print(f"    assign x_max = {x_max};")
print("")
print("    always_comb")
print("        case (x)")
for t in ts:
    x = xs[t] & (2**w - 1)
    print("        {0}: y = {1}'b{2:0{1}b};".format(t, w, x))
print("        default: y = {0}'b0;".format(w))
print("        endcase")
print("")
print("endmodule")
print("")

#import matplotlib.pyplot as plt
#
#plt.plot(ts, xs, '.', lw=2)
#plt.grid(True)
#plt.show()
