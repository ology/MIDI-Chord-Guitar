package MIDI::Chord::Guitar;

# ABSTRACT: MIDI pitches for guitar chord voicings

our $VERSION = '0.0400';

use strict;
use warnings;

use File::ShareDir qw(dist_dir);
use List::Util qw(any);
use Music::Note;
use Text::CSV_XS ();
use Moo;
use strictures 2;
use namespace::clean;

=head1 SYNOPSIS

  use MIDI::Chord::Guitar;

  my $mcg = MIDI::Chord::Guitar->new;

  my $chords = $mcg->transform('D3', 'dim7');
  # [ [41, 47, 50, 56], [50, 56, 59, 65, 68] ]

  my $chord = $mcg->transform('D3', 'dim7', 0);
  # [41, 47, 50, 56]

  # MIDI:
  #$score->n('wn', @$chord);

  my $voicings = $mcg->voicings('dim7');
  # [ [51, 57, 60, 66], [48, 54, 57, 63, 66] ]

  $voicings = $mcg->voicings('dim7', 'ISO');
  # [ [D#3 A3 C4 F#4], [C3 F#3 A3 D#4 F#4] ]

=head1 DESCRIPTION

C<MIDI::Chord::Guitar> provides MIDI pitches for common chord voicings
of an C<E A D G B E> tuned guitar.

=begin html

<p>Here is a handy diagram of ISO MIDI pitches laid out on a guitar neck:</p>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/main/guitar-position-midi-octaves.png">
<p>And here is a companion diagram of MIDI pitch numbers laid out on a guitar neck:</p>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/main/guitar-position-midi-numbers.png">

=end html

=head1 ATTRIBUTES

=head2 voicing_file

The CSV file with which to find the MIDI numbered chord voicings.

If not given, L<File::ShareDir> is used.

=cut

has voicing_file => (
  is => 'lazy',
);

sub _build_voicing_file {
    my ($self) = @_;
    my $file = eval { dist_dir('MIDI-Chord-Guitar') . '/midi-guitar-chord-voicings.csv' };
    return $file;
}

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

    my $file = $self->voicing_file;

    my %data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        my $chord = shift @$row;
        my $fingering = shift @$row;
        my @notes;
        for my $r (@$row) {
            push @notes, $r if $r ne '';
        }
        push @{ $data{$chord}{notes} }, \@notes;
    }

    close $fh;

    return \%data;
}

=head1 METHODS

=head2 transform

  $chord = $mcg->transform($target, $chord_name, $variation);
  $chords = $mcg->transform($target, $chord_name);

Find the chord given the B<target>, B<chord_name> and an optional
B<variation>.

The B<target> must be in the format of an C<ISO> note (e.g. on the
guitar, a C note is represented by C<C3>, C<C4>, C<C5>, etc).

If no B<chord_name> is given, C<major> is used.

If no B<variation> is given, all transformed voicings are returned.

For example, here are the open major chord specs for each note in the
key of C:

  'C3', '', 0
  'D3', '', 4
  'E2', '', 3
  'F2', '', 3
  'G2', '', 2
  'A2', '', 1
  'B2', '', 1

=cut

sub transform {
    my ($self, $target, $chord_name, $variation) = @_;

    $target = Music::Note->new($target, 'ISO')->format('midinum');

    $chord_name //= '';

    my @notes;

    if (defined $variation) {
      my $pitches = $self->chords->{ 'C' . $chord_name }{notes}[$variation];

      my $diff = $target - _lowest_c($pitches);

      @notes = map { $_ + $diff } @$pitches;
    }
    else {
        for my $pitches (@{ $self->chords->{ 'C' . $chord_name }{notes} }) {
            my $diff = $target - _lowest_c($pitches);
            push @notes, [ map { $_ + $diff } @$pitches ];
        }
    }

    return \@notes;
}

sub _lowest_c {
    my ($pitches) = @_;

    my $lowest = 0;

    for my $c (48, 60, 72) {
        if (any { $_ == $c } @$pitches) {
            $lowest = $c;
            last;
        }
    }

    return $lowest;
}

=head2 voicings

  $mcg->voicings($chord_name);
  $mcg->voicings($chord_name, $format);

Return all the voicings of a given B<chord_name> in the key of C.

The default B<format> is C<midinum> but can be given as C<ISO> or
C<midi> to return named notes with octaves.

The order of the voicing variations of a chord is by fret position.
So, the first variations are at lower frets.  Please use the above
diagrams to figure out the exact neck positions.

Here is an example of the voicing CSV file which can be found with the
B<voicing_file> attribute:

  C,48,52,55,60,,
  C,48,55,60,64,67,
  C,48,52,55,60,64,72
  C,48,55,60,64,67,72
  C,60,67,72,76,,
  C7,48,52,58,60,64,
  C7,48,55,58,64,67,
  C7,48,55,58,64,67,72
  C7,48,52,55,60,64,70
  C7,60,67,70,76,,
  ...

Check out the link in the L</"SEE ALSO"> section for the chord shapes
used to create this.

=cut

sub voicings {
    my ($self, $chord_name, $format) = @_;

    $chord_name //= '';
    $format ||= '';

    my $voicings = $self->chords->{ 'C' . $chord_name }{notes};

    if ($format) {
        my $temp;

        for my $chord (@$voicings) {
            my $span;

            for my $n (@$chord) {
                my $note = Music::Note->new($n, 'midinum')->format($format);
                push @$span, $note;
            }

            push @$temp, $span;
        }

        $voicings = $temp;
    }

    return $voicings;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/autumn_leaves> files in this distribution

L<File::ShareDir>

L<List::Util>

L<Moo>

L<Music::Note>

L<Text::CSV_XS>

L<https://www.guitartricks.com/chords/C-chord> shapes

=cut
