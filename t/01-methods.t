#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Chord::Guitar';

my $mcg = new_ok 'MIDI::Chord::Guitar';

#is $mcg->as_file, 'share/midi-guitar-chord-voicings.csv', 'as_file';

my $got = $mcg->transform('D3', '', 4);
is_deeply $got, [50, 57, 62, 66], 'transform';

$got = $mcg->transform('E2', '', 3);
is_deeply $got, [40, 47, 52, 56, 59, 64], 'transform';

done_testing();
