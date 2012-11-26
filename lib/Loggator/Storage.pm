# interface for a single pattern type
# set up Tables as per conf
# use general view for queries

use strict; use warnings;

use Loggator::Storage::Table;
use Loggator::Storage::View;


package Loggator::Storage ;

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
  $self->{backends}  = shift;
  my $logconfs = shift;
  $self->{logconfs} = {};
  $self->{connections} = {};
  $self->{tables} = {};

  foreach my $log ( keys %$logconfs ) {

    # possibly somehow move to Confer
    # reimplement with Tie::IxHash

    #storage data
    $self->{logconfs}{$log}{storage} = $logconfs->{$log}[0]{storage}
      if defined $logconfs->{$log}[0]{storage};

    #input data
    foreach my $pttrn (@{$logconfs->{$log}[0]{patterns}}) {
      my ( $pname ) = keys %{$pttrn};
      $self->{logconfs}{$log}{pttrn}{$pname}{field} = {};
      $self->{logconfs}{$log}{pttrn}{$pname}{fields} = [];

      foreach my $field (@{$pttrn->{$pname}{re}}) {
	my ( $fname ) = keys (%$field);
	next if substr($fname, 0, 1) eq '_';
	$fname =~ m/^([^:])(:?:(.*))?$/ ;
	$fname = (defined $1 ? $1 : $fname);
	my $ftype = (defined $2 ? $2 : 'str');
	push @{$self->{logconfs}{$log}{pttrn}{$pname}{fields}}, $fname;	# field order
	$self->{logconfs}{$log}{pttrn}{$pname}{field}{$fname} = $ftype;
      }
      foreach my $tag (keys %{$pttrn->{$pname}{tags}} ) {
	# add support for tag values with types
	#$tag =~ m/^([^:])(:?:(.*))?$/ ;
	#my $tvname = (defined $1 ? $1 : $tname);
	#my $tvtype = (defined $2 ? $2 : 'str');
	$self->{logconfs}{$log}{pttrn}{$pname}{tags}{$tag} = 1;
      }
    }

    unless (exists $self->{logconfs}{$log}{storage}) {
      warn "WARNING: No backend specified for $log, storage disabled.\n";
      next;
      die "Logfile configuration $log specifies $logconfs->{$log}[0]{storage},\n" .
	"but no such backend is defined by configuration (typo?). Aborting.\n"
	  unless exists $self->{backends}{$self->{logconfs}{$log}{storage}}};

    # setup backend objects
    my $backend = $self->{logconfs}{$log}{storage};

    # setup table list for results, with types
    # setup tables for tags (just presence, for now)

    for my $pttrn ( keys %{$self->{logconfs}{$log}{pttrn}} ) {
      # GET COLUMNS

    $DB::single = 2;
    $self->{frontends} = undef;
      $self->{frontends}{$log}{$pttrn} =
	{
	 loglines =>
	 Loggator::Storage::Table->new($backend, $pttrn . '_loglines',
				       { %{$self->{logconfs}{$log}{pttrn}{$pttrn}{field}}} ),
	 tagnames =>
	 Loggator::Storage::Table->new($backend, $pttrn . '_tag_names',
				       { map { ($_, 'str') } keys(%{$self->{logconfs}{$log}{pttrn}{$pttrn}{tags}})  } ),
	 tags =>
	 Loggator::Storage::Table->new($backend, $pttrn . '_tags',
				       { loglineID => 'num',
					 tagnameID => 'num', }),
	 view =>
	 Loggator::Storage::View->new($backend, $pttrn,
				      { loglineID => 'num',
					date => 'date', }),
	}
# 	  for my $tblname ( keys (%{$self->{frontends}{$log}{$pttrn}}) ) {
# 	    my $tbl;
# 	    $tbl = $self->{frontends}{$log}{$pttrn}{$tblname};
# 	    $self->{tables}{$tbl->{name}} = $tbl;
# 	  }
      }
  }
    $DB::single = 2;
}


#$storage->add($logconf, $match, $result, $tags);
sub add {
  my $logname = shift;
  my $ptrn    = shift;
  my $data    = shift;
  my $tags    = shift;

}

1;
