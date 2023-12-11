#!/usr/local/bin/perl
$|=1;

use Audio::Wav;

#
# Usage example:
#
# sudo sh -c "perl ./hex2wav.pl" > test.wav
#

my $serial_port = "/dev/cuaU0";
my $baud_rate = 921600;

system("stty -f $serial_port $baud_rate") && die "Cannot set port paramenters for $serial_port ($?)\n";

open(PORT, "$serial_port") or die "Cannot open serial port device $serial_port\n";

my $scale_factor = 2;

my %options = (
    '.01compatible'   => 0,
    'oldcooledithack' => 0,
    'debug'           => 0,
);
my $wav = Audio::Wav -> new(%options);

my $details = {
    'bits_sample'   => 16,
    'sample_rate'   => 10000,
    'channels'      => 1,
};

my $write = $wav -> write('-', $details);

$SIG{INT} = sub { $write->finish(); };
$SIG{TERM} = sub { $write->finish(); };

while(<PORT>) {
    if(length($_) < 6) { next; }
    $hex1 = substr($_, 0, 2);
    $hex2 = substr($_, 2, 2);
    $hex3 = substr($_, 4, 2);
    $sample = hex($hex1) * 65536 + hex($hex2) * 256 + hex($hex3);
    $write->write($sample >> $scale_factor);
}

$write->finish();
