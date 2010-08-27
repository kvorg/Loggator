# interface for a single table in a DB
# use Storage::DB to talk to the backend

package Storage::Table ;

use Storage::DB;

use strict; use warnings;

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

  $self->{db}    = shift ; # a Storage object, used for all communication
  $self->{table} = shift ; # tablename

  $self->{dbh} = undef;
  $self->{sth} = undef;
  $self->{connected} = undef;
}


1;
