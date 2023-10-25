package Music::MelodicDevice::Transposition;

# ABSTRACT: Apply chromatic and diatonic transposition to notes

our $VERSION = '0.0502';

use Moo;
use strictures 2;
use Data::Dumper::Compact qw(ddc);
use List::SomeUtils qw(first_index);
use Music::Scales qw(get_scale_MIDI is_scale);
use namespace::clean;

with('Music::PitchNum');

use constant OCTAVES => 10;

=head1 SYNOPSIS

  use Music::MelodicDevice::Transposition;

  my @notes = qw(C4 E4 D4 G4 C5); # either named notes or midinums

  # Chromatic
  my $md = Music::MelodicDevice::Transposition->new;
  $md->notes(\@notes);
  my $transposed = $md->transpose(2); # [D4, F#4, E4, A4, D5]
  $transposed = $md->transpose(4);    # [E4, G#4, F#4, B4, E5]
  $transposed = $md->transpose(4, \@notes); # same thing

  # Diatonic
  $md = Music::MelodicDevice::Transposition->new(scale_name => 'major');
  $md->notes(\@notes);
  $transposed = $md->transpose(2); # [E4, G4, F4, B4, E5]
  $transposed = $md->transpose(4); # [G4, B4, A4, D5, G5]

=head1 DESCRIPTION

C<Music::MelodicDevice::Transposition> applies transposition, both
chromatic or diatonic, to a series of ISO or "midinum" formatted
notes.

While there are modules on CPAN that do chromatic transposition,
none appear to apply diatonic transposition to an arbitrary series of
notes.  Hence this module.

=head1 ATTRIBUTES

=head2 scale_note

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);

=head2 scale_name

Default: C<chromatic>

For the chromatic scale, enharmonic notes are listed as sharps.  For a
scale with flats, a diatonic B<scale_name> must be used with a flat
B<scale_note>.

Please see L<Music::Scales/SCALES> for a list of valid scale names.

=for Pod::Coverage OCTAVES

=cut

has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid scale name" unless is_scale($_[0]) },
    default => sub { 'chromatic' },
);

has _scale => (
    is        => 'lazy',
    init_args => undef,
);

sub _build__scale {
    my ($self) = @_;

    my @scale = map { get_scale_MIDI($self->scale_note, $_, $self->scale_name) } -1 .. OCTAVES - 1;
    print 'Scale: ', ddc(\@scale) if $self->verbose;

    return \@scale;
}

=head2 notes

  $md->notes(\@notes);

The list of notes to use in transposition operations.

This can be overriden with a B<notes> argument given to the
B<transposition> method.

Default: C<[]> (no notes)

=cut

has notes => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid list" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);

=head2 verbose

Default: C<0>

=cut

has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head1 METHODS

=head2 new

  $md = Music::MelodicDevice::Transposition->new(
    scale_note => $scale_note,
    scale_name => $scale_name,
    notes      => \@notes,
    verbose    => $verbose,
  );

Create a new C<Music::MelodicDevice::Transposition> object.

=head2 transpose

  $transposed = $md->transpose($offset);
  $transposed = $md->transpose($offset, \@notes);

Return the transposed list of B<notes> given an B<offset>
appropriately based on the number of notes in the chosen scale.

=cut

sub transpose {
    my ($self, $offset, $notes) = @_;

    $notes ||= $self->notes;

    my $named = $notes->[0] =~ /[A-G]/ ? 1 : 0;

    my @transposed;

    for my $n (@$notes) {
        my ($i, $pitch) = $self->_find_pitch($n);
        if ($i == -1) {
            push @transposed, undef;
        }
        else {
            if ($named) {
                push @transposed, $self->pitchname($self->_scale->[ $i + $offset ]);
            }
            else {
                push @transposed, $self->_scale->[ $i + $offset ];
            }
        }
    }
    print 'Transposed: ', ddc(\@transposed) if $self->verbose;

    return \@transposed;
}

sub _find_pitch {
    my ($self, $pitch) = @_;

    $pitch = $self->pitchnum($pitch)
        if $pitch =~ /[A-G]/;

    my $i = first_index { $_ == $pitch } @{ $self->_scale };

    return $i, $pitch;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> test and the F<eg/*> example files

L<Data::Dumper::Compact>

L<List::SomeUtils>

L<Moo>

L<Music::Scales>

=cut
