#! /usr/bin/perl

# TODOS:
# -fix hash-in-array YAML thing
# -add multiple pattern support
# -consider a callback/loadable setup interface
# -fix tag infrastructure for nested tags (optimisation??)
# -add cmdline (ie. notags)

use strict; use warnings;

use Confer ;
use Parser ;
use Data::Dumper ;

my $conf = Confer->new('log.d');
$conf->process();

LOG: foreach my $logconf ( keys %{$conf->{confs}} ) {
  if ( open my $log, "<", $conf->{confs}{$logconf}[0]{logfile} )    {

    print "Parsing [$logconf]: $conf->{confs}{$logconf}[0]{logfile} ...\n";

    my $parser = Parser->new( $conf->{confs}{$logconf}[0]{patterns}, $conf->{confs}{$logconf}[0]{tags} );
    my $matches = 0;
    my $fails = 0;
    my %tags = ();

    while (<$log>) {
      my ($result, $match, $tags) = $parser->parse($_);
      $matches++ if $match;
      print "NOTAGS:\n$_\n" . Dumper($result) if ($match and not scalar @$tags);
      print "DAMN: no match!\n$_\n" and $fails++ unless $match;
      foreach (@$tags) {
	if (exists $tags{$_}) { $tags{$_}++ } else { $tags{$_} = 1} ;
      }
    }

    print "\t... done.\nMatches: $matches\t Fails: $fails (" .
      sprintf ("%4.2f", ( $fails / ($fails + $matches) * 100)) . " %)\n";
    foreach (keys %tags) {
      printf ("%22s:\t%9d (%04.2f %%)\n", $_, $tags{$_}, ($tags{$_} / ($fails + $matches) * 100)) ;
    }
  }  else  {
    warn "Can't read $conf->{confs}{$logconf}{logfile}, aborting logfile ($!)\n";
    next LOG;
  }
}

