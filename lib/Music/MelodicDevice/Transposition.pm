package Music::MelodicDevice::Transposition;

# ABSTRACT: Apply chromatic and diatonic transposition to notes

our $VERSION = '0.0102';

use List::SomeUtils qw(first_index);
use Music::Scales qw(get_scale_notes is_scale);
use Music::Note;
use Moo;
use strictures 2;
use namespace::clean;

=head1 SYNOPSIS

  use Music::MelodicDevice::Transposition;

  my @notes = qw(C4 E4 D4 G4 C5);

  # Chromatic
  my $md = Music::MelodicDevice::Transposition->new;
  my $transposed = $md->transpose(2, \@notes); # [D4, F#4, E4, A4, D5]
  $transposed = $md->transpose(4, \@notes); # [E4, G#4, F#4, B4, E5]

  # Diatonic
  $md = Music::MelodicDevice::Transposition->new(scale_name => 'major');
  $transposed = $md->transpose(2, \@notes); # [E4, G4, F4, B4, E5]
  $transposed = $md->transpose(4, \@notes); # [G4, B4, A4, D5, G5]

=head1 DESCRIPTION

C<Music::MelodicDevice::Transposition> applies transposition, both
chromatic or diatonic, to a series of ISO formatted notes.

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

    my @scale = get_scale_notes($self->scale_note, $self->scale_name);
    print 'Scale: ', ddc(\@scale) if $self->verbose;

    my @with_octaves = map { my $o = $_; map { $_ . $o } @scale } 0 .. 10;
    print 'With octaves: ', ddc(\@with_octaves) if $self->verbose;

    return \@with_octaves;
}

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
    verbose => $verbose,
  );

Create a new C<Music::MelodicDevice::Transposition> object.

=head2 transpose

  $transposed = $md->transpose($offset, $notes);

Return the transposed series of B<notes> given an B<offset>
appropriately based on the number of notes in the chosen scale.

=cut

sub transpose {
    my ($self, $offset, $notes) = @_;

    my @transposed;

    if ($self->scale_name eq 'chromatic') {
        my @pitches = map { Music::Note->new($_, 'ISO')->format('midinum') + $offset } @$notes;
        @transposed = map { Music::Note->new($_, 'midinum')->format('ISO') } @pitches;
    }
    else {
        for my $n (@$notes) {
            my $i = first_index { $_ eq $n } @{ $self->_scale };
            push @transposed, $i == -1 ? undef : $self->_scale->[ $i + $offset ];
        }
    }
    print "Transposed: @transposed\n" if $self->verbose;

    return \@transposed;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> test file

L<List::SomeUtils>

L<Moo>

L<Music::Note>

L<Music::Scales>

=cut
