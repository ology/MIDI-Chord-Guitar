package MIDI::Chord::Guitar;

# ABSTRACT: MIDI pitches for guitar chord voicings

our $VERSION = '0.0107';

use strict;
use warnings;

use File::ShareDir qw(dist_dir);
use List::Util qw(any);
use Moo;
use Music::Note;
use Text::CSV_XS;

=head1 SYNOPSIS

  use MIDI::Chord::Guitar;

  my $mcg = MIDI::Chord::Guitar->new;

  my $voicings = $mcg->voicings('dim7');

  my $chord = $mcg->transform('D3', 'dim7', 0);

  # MIDI:
  #$score->n('wn', @$chord);

=head1 DESCRIPTION

C<MIDI::Chord::Guitar> provides MIDI pitches for common chord voicings
of an C<E A D G B E> tuned guitar.

=begin html

<p>Here is a handy diagram of ISO MIDI pitches laid out on a guitar neck:</p>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/main/guitar-position-midi-octaves.png">
<p>And here is a diagram of MIDI pitch numbers laid out on a guitar neck:</p>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/main/guitar-position-midi-numbers.png">

=end html

=head1 ATTRIBUTES

=head2 chords

  $chords = $mcg->chords;

Computed attribute available after construction.

The chord names are given to the module methods as the B<chord_name>.
They are as follows:

  '' (major)
  aug
  dim
  dim7
  m (minor)
  m6
  m7
  m7b5
  m7b5#9
  m9
  m11
  maj7
  maj7#11
  maj9
  sus2
  sus4
  6
  6(9)
  7
  7#5
  7#9
  7b13
  7b5
  7b9
  7b9b13
  9
  9sus4
  11
  13

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

  $chord = $mcg->transform($target, $chord_name, $variation);

Find the chord given the B<target>, B<chord_name> and B<variation>.

The B<target> must be in the format of an C<ISO> note (e.g. on the
guitar, a C note is represented by C<C3>, C<C4>, C<C5>, etc).

If no B<chord_name> is given, C<major> is used.  If no B<variation> is
given, C<0> is used.

=cut

sub transform {
    my ($self, $target, $chord_name, $variation) = @_;
    $target = Music::Note->new($target, 'ISO')->format('midinum');
    $chord_name //= '';
    $variation //= 0;
    my $pitches = $self->chords->{ 'C' . $chord_name }[$variation];
    my $diff = $target - _lowest_c($pitches);
    my @notes = map { $_ + $diff } @$pitches;
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

=head2 voicings

  $mcg->voicings($chord_name);

Return all the voicings of a given B<chord_name>.

The order of the voicing variations of a chord is by fret position.
So, the first variations are at lower frets.  Please use the above
diagrams to figure out the exact neck positions.

=cut

sub voicings {
    my ($self, $chord_name) = @_;
    $chord_name //= '';
    return $self->chords->{ 'C' . $chord_name };
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

=cut
