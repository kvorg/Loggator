# TODO:
# differentiate log and dbase confs
# implement store/publish/join thingies in log conf, using dbase conf references
# implement handles: calling external scripts with several types of data arguments
#                    either on parse objects or join-data objects
package Loggator::Confer;

use YAML qw( LoadFile) ;
use File::Find;
use DateTime ; #just for logs

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

sub setlog {
  my $self = shift;
  $self->{logfile} = shift or warn "Setlog needs a logfile reference!\n";
}

sub receive {
  my $self = shift;
  my $confid = shift;
  my $confdata = shift;

  if ( $confid =~ m/.*[.]conf$/ ) { # XXX ugly hack
      $confid =~ s/^(.*)[.]conf$/$1/;
      #print ">>$confid<<\n";
      $self->{$confid} = $confdata;
  } else {
      $self->printlog("Overwriting existing configuration for $confid.\n") 
	  if exists $self->{confs}{$confid};
      $self->{confs}{$confid} = $confdata;
  }
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
  #warn ("Looking at $File::Find::name\n") ;
  return if (-d $_ or m{^#.*#$} or m {~$} ); # only parse files and ignore backups
  #warn ("Processing $File::Find::name\n") ;
  $confer->receive( $_, LoadFile ($_) );
}


sub printlog {
    my $self = shift;
    unless (defined $self->{logfile}) {
	warn @_;
	return ;
    }  
    my $log = $self->{logfile} ;
    my $dt = DateTime->now();
    print  $dt->ymd() . " " . $dt->hms() . " ", @_ ;
}


1;
__END__
