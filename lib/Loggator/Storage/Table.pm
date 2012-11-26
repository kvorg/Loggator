# interface for a single table in a DB
# use Storage::DB to talk to the backend

use strict; use warnings;

#use Loggator::Storage::DB;


package Loggator::Storage::Table ;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  $self->init(@_);

  return $self;
}

sub init {
  my $self = shift;
  $self->{backend} = shift;
  $self->{name}    = shift;
  $self->{columns} = shift;
  $self->{types} = shift;
}

sub columns {
  my $self = shift;
  return $self->{columns} ;
}

sub types {
  my $self = shift;
  return $self->{types} ;
}

sub insert {
  my $self = shift;
  $self->{backend}->insert($self, @_);
}

sub set_value {
}

sub select {
}

sub delete {
}


1;
