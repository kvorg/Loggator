# interface for a single pattern type
# set up Tables as per conf
# use general view for queries

package Storage ;

use Storage;

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
