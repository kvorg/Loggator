#! /usr/bin/perl

# TODOS:
# -fix hash-in-array YAML thing
# -add multiple pattern support
# -return mathced pattern or undef from Parser
# -consider a callback/loadable setup interface

use strict; use warnings;

use Confer ;
use Parser ;


my $conf = Confer->new('log.d');
$conf->process();

LOG: foreach my $logconf ( keys %{$conf->{confs}} ) {
  if ( open my $log, "<", $conf->{confs}{$logconf}[0]{logfile} )    {

    print "Parsing [$logconf]: $conf->{confs}{$logconf}[0]{logfile} ...\n";

    my $parser = Parser->new( $conf->{confs}{$logconf}[0]{patterns} );
    my $matches = 0;
    my $fails = 0;

    while (<$log>) {
      my ($result, $status) = $parser->parse($_);
      $matches++ if $status;
      print "DAMN: no match!\n$_\n" and $fails++ unless $status;
    }

    print "\t... done.\nMatches: $matches\t Fails: $fails (" .
      sprintf ("%4.2f", ( $fails / ($fails + $matches) * 100)) . " %)\n";

  }  else  {
    warn "Can't read $conf->{confs}{$logconf}{logfile}, aborting logfile ($!)\n";
    next LOG;
  }
}

