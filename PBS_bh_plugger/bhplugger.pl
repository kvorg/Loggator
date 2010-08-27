#! /usr/bin/perl

# from a version of testparse
# this is a quick hack
# replace with a loggator script when available

# send message for bh events and any ops fails!

use strict; use warnings;

use Loggator::Confer ;
use Loggator::Parser ;
use Loggator::Storage ;
use Data::Dumper ;

my $conf = Loggator::Confer->new('log.d');
$conf->process();

print "Configuration processing finished.\n\n";

my $storage = Loggator::Storage->new( $conf->{backends}, $conf->{confs}  );
$DB::single = 2;

LOG: foreach my $logconf ( keys %{$conf->{confs}} ) {
  if ( open my $log, "<", $conf->{confs}{$logconf}[0]{logfile} )    {

    print "Parsing [$logconf]: $conf->{confs}{$logconf}[0]{logfile} ...\n";

    my $parser = Loggator::Parser->new( $conf->{confs}{$logconf}[0]{patterns} );
    my $matches = 0;
    my %matches = ();
    my $fails = 0;
    my %tags = ();

    while (<$log>) {
      my ($result, $match, $tags) = $parser->parse($_);
      $matches++ if $match;
      $matches{$match} = defined $matches{$match} ? $matches{$match} + 1 : 1;
      print "NOTAGS:\n$_\n" . Dumper($result) if ($match and not scalar @$tags);
      print "DAMN: no match!\n$_\n" and $fails++ unless $match;
      print "Ops: $result->{used_cput}\n" if exists $result->{queue} and exists  $result->{used_cput} and $result->{queue} eq 'ops';
      foreach (@$tags) {
	if (exists $tags{$_}) { $tags{$_}++ } else { $tags{$_} = 1} ;
#	print "Failure:\n", Dumper($result, $tags), "\n" if $_ eq 'failure';
	print "(Failed ops.)\n" if $_ eq 'failure' and $result->{queue} eq 'ops';;
      }
      #$storage->add($logconf, $match, $result, $tags);
    }

    print "\t... done.\nMatches: $matches\t Fails: $fails (" .
      sprintf ("%4.2f", ( $fails / ($fails + $matches) * 100)) . " %)\n";
    print "Matched patterns:\n";
    foreach (keys %matches) {
      printf ("%32s:\t%9d (%04.2f %%)\n", $_, $matches{$_}, ($matches{$_} / ($fails + $matches) * 100)) ;
    }
    print "Matched tags:\n";
    foreach (keys %tags) {
      printf ("%32s:\t%9d (%04.2f %%)\n", $_, $tags{$_}, ($tags{$_} / ($fails + $matches) * 100)) ;
    }
  }  else  {
    warn "Can't read $conf->{confs}{$logconf}{logfile}, aborting logfile ($!)\n";
    next LOG;
  }
}

__END__
#conversions for durations of form hh:mm:ss
sub time_to_sec {
    $_ = shift ; m{^(\d\d+):(\d\d):(\d\d)$} or
      warn "Not a time duration string: $_.\n" and return undef  ;
      warn "Not a time duration string: $_.\n" and return undef
	if ($2 > 59 or $3 > 59);
    return $1 * 60 * 60 + $2 * 60 + $3 ;
}

sub sec_to_time {
    my $s = shift;
    my $msec = $s % 60**2;
    my $h = ($s - $msec) / 60**2;
    my $sec = $msec % 60;
    my $m = ($msec - $sec) / 60;
    return (join ':', ( sprintf('%02d', $h),
			sprintf('%02d', $m),
			sprintf('%02d', $sec)
		      )
	   );
}

