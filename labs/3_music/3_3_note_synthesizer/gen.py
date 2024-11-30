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

usage = f"usage:\n{argv[0]} [--freq freq_in_hz | --note C|Cs|D|Ds|E|F|Fs|G|Gs|A|As|B] bit_width sampling_rate freq_in_hz volume 15-10_bit"

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
A = 2**vol - 1

N = floor((Fs / F / 4) + 2)
x_max = N - 1
x_width = x_max.bit_length()
y_width = w

ts = [t for t in range(N)]
xs = [round(A * sin(pi * t / N / 2)) for t in ts]

print("// y(t) = sin(pi*F*t/2), F={0}Hz, Fs={1}Hz, {2}-bit, Volume {3}/15 bit".format(F, Fs, w, vol))
print("")
if note is None:
    print("module table")
else:
    print(f"module table_{Fs}_{note}")
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
