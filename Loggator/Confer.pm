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

  if ( $confid eq 'backends.conf' ) { # XXX ugly hack
      $self->{backends} = $confdata;
  }
  else {
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

# accessors

sub log_names {
    my $self = shift;
    return grep { exists $_->{confs}{$_}[0]{logfile} } keys %{$self->{confs}} ;
}

sub log_file  {
    my $self = shift;
    my $log_name = shift;
    return  $self->{confs}{$log_name}[0]{logfile} ;
}

sub log_files  {
    my $self = shift;
    return grep { $_->{confs}{$_}[0]{logfile} } keys %{$self->{confs}} ;
}

sub backends {
    my $self = shift;
    return grep { exists $_->{backend}{$_}[0]{logfile} } keys %{$self->{confs}} ;
}

sub Backends {
    my $self = shift;
    return map { Confer::Backend->new($_, $_->{backend}{$_}[0]) } $self->backends();
}

sub Logs {
    my $self = shift;
    my $backend = shift;
    return map { Confer::Log->new($_, $_->{confs}{$_}[0]) }
      grep { not defined $backend 
	     or  defined $backend and $_->{confs}{$_}[0]{storage} eq $backend }
	$self->log_files();
}


# utility

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

package Confer::Backend ;

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
  $self->{name} = shift;
  $self->{conf} = { @_ } ;
}

sub name { my $self = shift; return $self->{name} } ;

sub db { my $self = shift; return $self->{conf}{db} } ;
sub args { my $self = shift; return $self->{conf}{args} } ;
sub host { my $self = shift; return $self->{conf}{args}{host} } ;
sub port { my $self = shift; return $self->{conf}{args}{port} } ;
sub database { my $self = shift; return $self->{conf}{args}{database} } ;
sub dbname { my $self = shift; return $self->{conf}{args}{dbname} } ;
sub user { my $self = shift; return $self->{conf}{args}{user} } ;
sub password { my $self = shift; return $self->{conf}{args}{password} } ;
sub options { my $self = shift; return $self->{conf}{args}{options} } ;

sub dbi { 
  my $self = shift;
  my $dbi = $self->db();
  if ( $self->db() eq 'DBI::SQLite' ) {
    $dbi .= ':' . $self->dbname() ;
  } else {
    $dbi .= ':dbnbame=' . $self->dbname() ;
    $dbi .= ':host=' . $self->host() if $self->host();
    $dbi .= ':port=' . $self->port() if $self->port();
  }
  return $dbi;
}

sub filename {
  my $self = shift;

  return $self->dbname()
    if $self->db() eq 'DBI::SQLite' ;
} ;


1;

package Confer::Log ;

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
  $self->{name} = shift;
  $self->{conf} = { @_ } ;
}

sub name { my $self = shift; return $self->{name} } ;

sub logfile { my $self = shift; return $self->{conf}{logfile} } ;
sub storage { my $self = shift; return $self->{conf}{storage} } ;
sub patterns { my $self = shift; return $self->{conf}{patterns} } ;

sub specs {

  # return { name => '', kind => 'value', type => 'string', log => 'log1', logfile => '/path/to/log },
  # convenience: use string as default for patterns and boolean for tags

  my $self = shift;
  my @specs = ();

  push @specs, map {
    my ($name) =  keys %$_ ; $name =~ s/([^.]*)([.].+)/$1/ ;
    my $type = $2; $type ||= 'string' ;
    { name => $_-> $name, kind => 'value', type => $type,
	log => $self->name, logfile => $self->logfile }
  }
    @{$self->{conf}{patterns}} ;

  push @specs, map {
    my ($name) =  keys %$_ ; $name =~ s/([^.]*)([.].+)/$1/ ;
    my $type = $2; $type ||= 'bool' ;
    { name => $_-> $name, kind => 'tag', type => $type,
	log => $self->name, logfile => $self->logfile }
  }
    @{$self->{conf}{tags}} ;

  return @specs;
}

1;

__END__
