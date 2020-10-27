#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Chord::Guitar';

my $mcg = new_ok 'MIDI::Chord::Guitar';

#is $mcg->as_file, 'share/midi-guitar-chord-voicings.csv', 'as_file';

my $got = $mcg->as_hashref->{C}[4]; # C major at position X
is_deeply $got, [60, 67, 72, 76], 'as_hashref';
is $mcg->lowest_c($got), 60, 'lowest_c';
$got = $mcg->transform($got, 50); # Down to bottom D
is_deeply $got, [50, 57, 62, 66], 'transform';

$got = $mcg->as_hashref->{C}[3]; # C major barre at position VIII
is_deeply $got, [48, 55, 60, 64, 67, 72], 'as_hashref';
is $mcg->lowest_c($got), 48, 'lowest_c';
$got = $mcg->transform($got, 40); # Down to bottom E
is_deeply $got, [40, 47, 52, 56, 59, 64], 'transform';

done_testing();
