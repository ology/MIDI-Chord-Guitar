package MIDI::Chord::Guitar;

# ABSTRACT: MIDI pitches for guitar chord voicings

our $VERSION = '0.0100';

use strict;
use warnings;

use List::Util qw(any);
use Moo;
use Text::CSV_XS;
use File::ShareDir qw(dist_dir);

=head1 NAME

MIDI::Chord::Guitar - MIDI pitches for guitar chord voicings

=head1 SYNOPSIS

  use MIDI::Chord::Guitar;

  my $mcg = MIDI::Chord::Guitar->new;

  my $chord = $mcg->chords->{C}[2]; # C major barre at position III
  my $transformed = $mcg->transform($chord, 50); # Up to D

  $chord = $mcg->chords->{C}[4]; # C major at position X
  $transformed = $mcg->transform($chord, 50); # Down to D

  # MIDI:
  #$score->n('wn', @$transformed);

=head1 DESCRIPTION

C<MIDI::Chord::Guitar> provides MIDI pitches for common chord voicings
of an C<E A D G B E> tuned guitar.

=begin html

Here is a handy diagram of MIDI pitch numbers laid out on a guitar neck:
<br>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/master/guitar-position-midi-numbers.png">
<br>

=end html

=head1 ATTRIBUTES

=head2 chords

  $chords = $mcg->chords;

Computed attribute available after construction.

=cut

has chords => (
  is       => 'lazy',
  init_arg => undef,
);

sub _build_chords {
    my ($self) = @_;

    my $file = $self->as_file();

    my %data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        my $key = shift @$row;
        my @notes;
        for my $r (@$row) {
            push @notes, $r if $r ne '';
        }
        push @{ $data{$key} }, \@notes;
    }

    close $fh;

    return \%data;
}

=head1 METHODS

=head2 as_file

  $filename = $mcg->as_file;

Return the guitar chord data filename location.

=cut

sub as_file {
    my ($self) = @_;
    my $file = eval { dist_dir('MIDI-Chord-Guitar') . '/midi-guitar-chord-voicings.csv' };
    $file = 'share/midi-guitar-chord-voicings.csv'
        unless $file && -e $file;
    return $file;
}

=head2 transform

  $transformed = $mcg->transform($pitches, $target);

Find the difference in the B<pitches> between the B<target> and the
lowest guitar range C<C>.

The B<target> must be in the format of a C<midinum> (e.g. C is equal
to the note numbers 48, 60, or 72).

=cut

sub transform {
    my ($self, $pitches, $target) = @_;
    my $lowest = _lowest_c($pitches);
    my $diff = $target - $lowest;
    my @notes;
    for my $pitch (@$pitches) {
        push @notes, $pitch + $diff;
    }
    return \@notes;
}

sub _lowest_c {
    my ($pitches) = @_;
    my $lowest = 0;
    if (any { $_ == 48 } @$pitches) {
        $lowest = 48;
    }
    elsif (any { $_ == 60 } @$pitches) {
        $lowest = 60;
    }
    elsif (any { $_ == 72 } @$pitches) {
        $lowest = 72;
    }
    return $lowest;
}

1;
__END__

L<File::ShareDir>

L<List::Util>

L<Moo>

L<Text::CSV_XS>

1;
