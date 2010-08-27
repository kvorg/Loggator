# TODO:
# differentiate log and dbase confs
# implement store/publish/join thingies in log conf, using dbase conf references
# implement handles: calling external scripts with several types of data arguments
#                    either on parse objects or join-data objects
package Loggator::Confer;

use YAML qw( LoadFile) ;
use File::Find;

use strict; use warnings;


# $File::Find::dont_use_nlink = 1; #AFS - should work automatically these days

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
  $self->{confdirs} = [ @_ ] ;
  $self->{confs} = {};
}

sub receive {
  my $self = shift;
  my $confid = shift;
  my $confdata = shift;

  warn "Overwriting existing configuration for $confid.\n" 
    if exists $self->{confs}{$confid};
  $self->{confs}{$confid} = $confdata;
}

sub process {
  my $self = shift;
  use vars qw ( $confer ) ;
  local $confer; $confer = $self ;
  find(\&process_conf, @{$self->{confdirs}});

  #use Data::Dumper ;
  #print Dumper $self->{confs};
}

sub process_conf {
  use vars qw ( $confer ) ;
  warn "Looking at $File::Find::name\n" ;
  return if (-d $_ or m{^#.*#$} or m {~$} ); # only parse files and ignore backups
  warn "Processing $File::Find::name\n" ;
  $confer->receive( $_, LoadFile ($_) );
}


1;
__END__
