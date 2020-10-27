#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::Chord::Guitar';

my $mcg = new_ok 'MIDI::Chord::Guitar';

my $got = $mcg->transform('D3', '', 4);
my $expect = [50, 57, 62, 66];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('E2', '', 3);
$expect = [40, 47, 52, 56, 59, 64];
is_deeply $got, $expect, 'transform';

$got = $mcg->transform('D3', 'dim7', 0);
$expect = [41, 47, 50, 56];
is_deeply $got, $expect, 'transform';

$got = $mcg->voicings('dim7');
$expect = [ [51, 57, 60, 66], [48, 54, 57, 63, 66] ];
is_deeply $got, $expect, 'voicings';

done_testing();
