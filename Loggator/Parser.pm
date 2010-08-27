package Loggator::Parser;

use strict; use warnings;
use re qw (eval);
use subs qw (testall);

#non-methods
sub testall (&@) {
  my $test = shift;
  my $status = 1;

  foreach (@_) {
    $status &&= &$test ;
  }
    return $status;
}


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
  $self->{patterns} = shift ;
  $self->{tags} = {} ;
  $self->{res} = [] ;
  $self->{re} = {} ;

  foreach (@{$self->{patterns}}) {
    my ( $pname ) = keys %{$_};
    push @{$self->{res}}, $pname;  # save pattern order
    $self->{re}{$pname} = buildre( \@{$_->{$pname}{re}} , '$self->{results}');
    $self->{tags}{$pname} = { %{$_->{$pname}{tags}} };
  }
  #use Data::Dumper;
  #print Dumper ($self);
}


sub buildre {
    #$DB::single = 2;

    my $pttrn = shift;
    my $where = shift;

    my $re = join "\n", map {
	my ($a) = keys %$_;
	$_->{$a} . ($a =~ m/^_/ ? '' : ' (?{ ' . $where . '{' . $a . '}=$^N })');
    } @$pttrn;
    return $re;
}


sub parse {
  my $self = shift;
  my $line = shift;

  $self->{results} = {} ; # used directly from mangled patterns, as set in init()
  my $matched;
  my $tags = [];

  $matched = $self->{res}[0] if (m/$self->{re}{$self->{res}[0]}/x) ; #matches fist pattern:
                                                              #FIX to support many pttrns
  #TODO: upgrade tags to allow either one match or a named multimatch pattern
  #use buildre() to build such patterns both for patterns and tags

  $DB::single = 2;

  @$tags = grep {
    my $tag = $_;
    testall { exists $self->{results}{$_}
		and $self->{results}{$_} =~ m{$self->{tags}{$self->{res}[0]}{$tag}{$_}} ; }
      keys %{$self->{tags}{$self->{res}[0]}{$tag}} ;
  } keys %{$self->{tags}{$self->{res}[0]}} ;

#  print "DEBUG: " . join (', ', keys %{$self->{tags}{$self->{res}[0]}} );

  return ($self->{results}, $matched, $tags);
}

1;

