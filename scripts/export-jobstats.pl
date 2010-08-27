#! /usr/bin/perl

#env RGMA_HOME=/opt/glite APEL_HOME=/opt/glite /opt/glite/bin/apel-publisher -f /opt/glite/etc/glite-apel-publisher/publisher-config-yaim.xml
# INSERT INTO MessageRecords (MsgID,GramScriptJobID,JobName,Processed,SiteName,ValidFrom,ValidUntil) VALUES('2006-01-26 12:42:55 108212.brenta.ijs.si SiGNET', '108212.brenta.ijs.si', '108212.brenta.ijs.si', 0, 'SiGNET', '2006-01-25', '2006-02-23');
#/usr/local/libexec/fix-LocalUserGroup.sh

# TODOS:
# -fix hash-in-array YAML thing
# -add multiple pattern support
# -consider a callback/loadable setup interface
# -fix tag infrastructure for nested tags (optimisation??)
# -add cmdline (ie. notags)

# THINKOS:
# add sticky values (that are added from previous log lines until superceeded by new ones)
# example: gridftpd log ID numbers.

use strict; use warnings;

use Loggator::Confer ;
use Loggator::Parser ;
#use Loggator::Storage ;
use Data::Dumper ;
use DateTime ;

my $conf = Loggator::Confer->new('log.d');
$conf->process();

print "Configuration processing finished.\n\n";

#my $storage = Loggator::Storage->new( $conf->{backends}, $conf->{confs}  );
#$DB::single = 2;

open SQL, ">gmjobs-update.sql"
  or die "Can't open SQL dump file gmjobs-update.sql, @!\n";
open SQLVAL, ">gmjobs-validate.sql"
  or die "Can't open SQL dump file gmjobs-validate.sql, @!\n";
print SQLVAL "CREATE TABLE tmp AS SELECT * FROM NGValidate WHERE 1 = 0;\n";


LOG: foreach my $logconf ( keys %{$conf->{confs}} ) {
  if ( open my $log, "<", $conf->{confs}{$logconf}[0]{logfile} )    {

    print "Parsing [$logconf]: $conf->{confs}{$logconf}[0]{logfile} ...\n";

    my $parser = Loggator::Parser->new( $conf->{confs}{$logconf}[0]{patterns} );
    my $matches = 0;
    my %matches = ();
    my $fails = 0;
    my %tags = ();

    while (<$log>) {
      my %this_tags = ();
      my ($result, $match, $tags) = $parser->parse($_);
      $matches++ if $match;
      $matches{$match} = defined $matches{$match} ? $matches{$match} + 1 : 1;
      print "NOTAGS:\n$_\n" . Dumper($result) if ($match and not scalar @$tags);
      print "DAMN: no match!\n$_\n" and $fails++ unless $match;
      foreach (@$tags) {
	if (exists $tags{$_}) { $tags{$_}++ } else { $tags{$_} = 1} ;
	$this_tags{$_} = 1;
      }
      #$storage->add($logconf, $match, $result, $tags);
      if ( $logconf eq 'gm-jobs.log'
	   and $match eq 'standard'
	   and exists $this_tags{finished}
	 and not exists $this_tags{failed} ) {
	if ( defined $result->{date}
		 and defined $result->{time}
		 and defined $result->{lrmsid}
		 and defined $result->{ownerDN} ) {
	  $result->{date} =~ m/^(\d+)-(\d+)-(\d+)$/;
	  my ($day, $month, $year) = ($1, $2, $3);
	  my $dt = new DateTime ( month => $month, day => $day, year => $year );
	  my $dt_before = $dt - new DateTime::Duration( days => 1);
	  my $dt_after  = $dt + new DateTime::Duration( days => 28);
	  my $date   = $dt->ymd() ;
	  my $before = $dt_before->ymd() ;
	  my $after  = $dt_after->ymd()  ;
	  my $jobid  = $result->{lrmsid} ? $result->{lrmsid} . '.ijs.si' : 'ERROR';
	  my $id = "$date $result->{time} $jobid brenta.ijs.si SiGNET";

	  print SQL << "FNORD";
INSERT INTO GkRecords (GkID, GramScriptJobID, LocalJobID, Processed, GlobalUserName, SiteName, ValidFrom, ValidUntil) VALUES ( '$id', '$jobid', '$jobid', 0, '$result->{ownerDN}', 'SiGNET', '$before', '$after'  ) ;
INSERT INTO MessageRecords (MsgID, GramScriptJobID, JobName, Processed, SiteName, ValidFrom, ValidUntil) VALUES ('$id', '$jobid', '$jobid', 0, 'SiGNET', '$before', '$after');
UPDATE EventRecords SET LocalUserGroup = 'atlas' WHERE Jobname = '$jobid' ;
FNORD
	  print SQLVAL << "FNORD";
INSERT INTO tmp  (LocalJobID, Date) VALUES ( '$jobid', '$date'); INSERT INTO NGValidate SELECT tmp.LocalJobID, tmp.Date FROM tmp WHERE LocalJobID NOT IN (SELECT EventRecords.Jobname AS LocalJobID FROM EventRecords WHERE EventRecords.Jobname = '$jobid' AND EventRecords.EventDate = '$date') ; DELETE FROM tmp;
FNORD
 } else {
	print "SKIPPING STRANGE OBJECT:\n$_\n" . Dumper($result) . "\n"
}
      }
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

print SQLVAL "DROP TABLE tmp;\n";

