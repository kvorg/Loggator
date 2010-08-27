package Loggator::Parser;

use strict; use warnings;
use re qw (eval);

use Loggator::utils qw( testall ) ;


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
    my $pttrn = shift;
    my $where = shift;

    my $re = join "\n", map {
	my ($a) = keys %$_;
	my $aname = $a; $aname =~ s/([^.]*)([.].+)/$1/ ; #omit types
	$_->{$a} . ($a =~ m/^_/ ? '' : ' (?{ ' . $where . '{' . $aname . '}=$^N })');
    } @$pttrn;
    return $re;
}


sub parse {
  my $self = shift;
  my $line = shift;

  $self->{results} = {} ; # mangled patterns store directly here
                          # (mangled by buildre() in init() to use (?{ $^N })
  my $matched;
  my $tags = [];

  foreach my $pattern (@{$self->{res}}) {
    if (m/$self->{re}{$pattern}/x) {
      $matched = $pattern;

      #TODO:
      # upgrade tags to allow either
      #  (1) one match or a (2) named multimatch pattern
      # use buildre() to build such patterns both for patterns and tags
      #  (buildre() is already updated for the capability)

      @$tags = grep {
	my $tag = $_;
	testall { exists $self->{results}{$_}
		    and $self->{results}{$_} =~
		      m{$self->{tags}{$pattern}{$tag}{$_}} ;
		}
	  keys %{$self->{tags}{$pattern}{$tag}} ;
      } keys %{$self->{tags}{$pattern}} ;

      last;
    }
  }

  return ($self->{results}, $matched, $tags);
  #print "DEBUG: " . join (', ', keys %{$self->{tags}{$self->{res}[0]}} );
}

1;

