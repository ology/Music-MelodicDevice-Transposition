#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Transposition';

my @notes = qw(C4 E4 D4 G4 C5);

my $obj = new_ok 'Music::MelodicDevice::Transposition';
my $expect = ['D4','F#4','E4','A4','D5'];
my $got = $obj->transpose(2, \@notes);
is_deeply $got, $expect, 'transpose';
$expect = ['E4','G#4','F#4','B4','E5'];
$got = $obj->transpose(4, \@notes);
is_deeply $got, $expect, 'transpose';

$obj = new_ok 'Music::MelodicDevice::Transposition' => [ scale_name => 'major' ];
$expect = ['E4','G4','F4','B4','E5'];
$got = $obj->transpose(2, \@notes);
is_deeply $got, $expect, 'transpose';
$expect = ['G4','B4','A4','D5','G5'];
$got = $obj->transpose(4, \@notes);
is_deeply $got, $expect, 'transpose';

@notes = ('C4','E4','D#4','G4','C5');
$expect = ['E4','G4',undef,'B4','E5'];
$got = $obj->transpose(2, \@notes);
is_deeply $got, $expect, 'transpose';

done_testing();
