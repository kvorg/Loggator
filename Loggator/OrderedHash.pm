package Loggator::OrderedHash;

use strict; use warnings;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = [@_];
  bless $self, $class;

  return $self;
}

use overload '%{}' => \&gethash, '@{}' => sub { $ {shift()} };

sub gethash {
  my $self = shift;
  my %h;

  tie %h, ref $self, $self;
  \%h;
}

sub TIEHASH { my $p = shift; bless \ shift, $p }

my %fields;
my $i = 0;
$fields{$_} = $i++ foreach qw{zero one two three};

sub STORE {
  my $self = ${shift()};
  my $key = $fields{shift()};
  defined $key or die "Out of band access";
  $$self->[$key] = shift;
}

sub FETCH {
  my $self = ${shift()};
  my $key = $fields{shift()};
  defined $key or die "Out of band access";
  $$self->[$key];
}
