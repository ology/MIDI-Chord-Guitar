#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Chord::Guitar';

my $mcg = new_ok 'MIDI::Chord::Guitar';

#is $mcg->as_file, 'share/midi-guitar-chord-voicings.csv', 'as_file';

my $got = $mcg->as_hashref->{C}[4];

is_deeply $got, [60, 67, 72, 76], 'as_hashref';

is $mcg->lowest_c($got), 60, 'lowest_c';

$got = $mcg->transform($got, 50);

is_deeply $got, [50, 57, 62, 66], 'transform';

done_testing();
