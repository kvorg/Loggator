#! /usr/bin/perl -w

# This is a quick hack using the loggator log parser in progress
# to parse gmjobs.log and post results directly to lcgce's mysql.

# To be replaced with a loggator export directive once loggator is ready.

# It has a critical condition on time to be run from cron:
# it MUST run between /etc/cron.d/edg-apel-pbs-parser and
# and /etc/cron.d/edg-apel-publisher to ensure pbs data is parsed
# by apel and our data from gmjobs.log is published with
# the regular publish push.

# It gets all data on previous run from checking with lcgce's mysql
# so it should republish missing things.


use strict; use warnings;

use Getopt::Long ;

use Loggator::Confer ;
use Loggator::Parser ;
#use Loggator::Storage ; #wishful future
use Data::Dumper ;
use DateTime ;
use DBI;

#setup

my $version = '0.3';
my $progname = $0; $progname =~ s{(.*/)?([^/]+)$}{$2} ;

my $config = 'jobstat.rc' ;
my $logfile = 'jobstat.log' ;
my $statefile = 'jobstat.state' ;
my $nocommit = 0;
my $reparse= 0;
my $verbose = 0;
my $debug = 0;
my $withundo = 0;
my $help = 0;

my $hostname = 'xxx.ijs.si';
my $port =     'xxx';
my $database = 'accounting';
my $user =     'accounting';
my $passwd =    'xxx';

Getopt::Long::Configure qw(no_ignore_case);
GetOptions ( 'config|c=s'   => \$config,
	     'logfile|l=s'  => \$logfile,
             'statefile|s=s'=> \$statefile,
	     'nocommit|n'   => \$nocommit,
	     'reparse|r'    => \$reparse,
	     'verbose|v'    => \$verbose,
	     'debug|d'      => \$debug,
	     'withundo|u=s' => \$withundo, 
	     'hostname|H=s' => \$hostname,
	     'port|p=i'     => \$port,
	     'database|b=s' => \$database,
	     'username|U=s' => \$user,
	     'password|P=s' => \$passwd,   #FIXME: need use of backend conf file!
	     'help|h'       => \$help,
	   );

usage () and exit (0) if $help ;

my $prevpos ;
my $lastpos ;
my $previd ;

my $skipped = 0 ;
my $posted = 0 ;
my $startfrom ;
my $dt ;
my $undofile ;
my $nocommitmsg = '';

open our $log, ">>", $logfile
  or die "Can't open logfile $logfile, @!\n";
$| = 1, select $_ for select $log; #log to autoflush :-)
open STATE, "<", $statefile
  or warn "Can't open state file $statefile for reading, @!\n" unless $reparse ;

printlog ("\u$progname v $version starting.\n");

my $dbh = DBI->connect("DBI:mysql:database=$database;host=$hostname;port=$port",
 		       $user, $passwd,
		      { RaiseError => 1, AutoCommit => 0 },
		      )
  or die "Can't connect to mysql at $hostname:$port as $user.\n"
  if $hostname;
printlog ("! MySQL hostname not set - dry run!\n") unless $hostname;
warn "MySQL hostname not set - dry run!\n" unless $hostname;

if ($withundo) {
    my $start = DateTime->now();
    my $date = $start->ymd() ;
    my $time = $start->hms() ;
    $withundo =~ s{%d}{$date}g ;
    $withundo =~ s{%t}{$time}g ;
    open ($undofile, '>>', $withundo) or printlog ("Failed to open undo file $withundo: $!\n");
    printlog ("Writing undo to $withundo.\n") if $undofile ;
}


# Configuration
my $conf = Loggator::Confer->new($config);
$conf->setlog($log);
$conf->process();

printlog ("Configuration processing of $config finished.\n");

#my $storage = Loggator::Storage->new( $conf->{backends}, $conf->{confs}  );
#$DB::single = 2;

my $rewind = 0;

unless ($reparse) {
  while (<STATE>) {
    m/^\S+\s+\S+\s+(\d+)/ ;
    $rewind = $1 ;
  }
}


LOG: foreach my $logconf ( keys %{$conf->{confs}} ) {
  if ( open my $log, "<", $conf->{confs}{$logconf}[0]{logfile} )    {

    printlog("Parsing [$logconf]: $conf->{confs}{$logconf}[0]{logfile} ...\n");

    if ($rewind and not $reparse) {
      seek($log, $rewind, 0);
      printlog ("Rewinding $conf->{confs}{$logconf}[0]{logfile} to $rewind.\n");
    } else {
      printlog ("No rewind position to seek to, starting ab initio.\n") unless $rewind;
      printlog ("Reparse requested, starting ab initio.\n") if $reparse;
    }
    printlog ("Nocommit requested, dryrun (no actual data written to the database).\n") if $nocommit;
    $nocommitmsg = ' (But no commit actually done.)' if $nocommit;

    my $parser = Loggator::Parser->new( $conf->{confs}{$logconf}[0]{patterns} );
    my $matches = 0;
    my %matches = ();
    my $fails = 0;
    my %tags = ();
    my $lastpos; my $prepos ; my $preid ;

    my $insGK = $dbh->prepare('INSERT INTO GkRecords (GkID, GramScriptJobID, LocalJobID, Processed, GlobalUserName, SiteName, ValidFrom, ValidUntil) VALUES ( ?, ?, ?, ?, ?, ?, ?, ? );') or die $dbh->errstr;;
    my $insMR = $dbh->prepare('INSERT INTO MessageRecords (MsgID, GramScriptJobID, JobName, Processed, SiteName, ValidFrom, ValidUntil) VALUES (?, ?, ?, ?, ?, ?, ?);') or die $dbh->errstr;

    while (<$log>) {
      my %this_tags = ();
      my ($result, $match, $tags) = $parser->parse($_);
      $matches++ if $match;
      $matches{$match} = defined $matches{$match} ? $matches{$match} + 1 : 1;
      printlog ("NOTAGS:\n$_\n" . Dumper($result)) if ($match and not scalar @$tags);
      printlog ("DAMN: no match!\n$_\n") and $fails++ unless $match;
      foreach (@$tags) {
	if (exists $tags{$_}) { $tags{$_}++ } else { $tags{$_} = 1} ;
	$this_tags{$_} = 1;
      }
      #$storage->add($logconf, $match, $result, $tags);
      #and this is a poor man's replacement for jobstat-parser:
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
	  $dt = new DateTime ( month => $month, day => $day, year => $year );
	  my $dt_before = $dt - new DateTime::Duration( days => 1);
	  my $dt_after  = $dt + new DateTime::Duration( days => 28);
	  my $date   = $dt->ymd() ;
	  my $before = $dt_before->ymd() ;
	  my $after  = $dt_after->ymd()  ;
	  my $jobid  = $result->{lrmsid} ? $result->{lrmsid} . '.ijs.si' : 'ERROR';
	  my $id = "$date $result->{time} $jobid brenta.ijs.si SiGNET";

	  # FIXTHIS to check if it is in, warn to log (die if several)
	  #         else insertnano
	  if ($hostname) {
	    my $ref = $dbh->selectrow_hashref("SELECT * FROM GkRecords WHERE GkID = '$id' AND ValidFrom = '$before';");
	    if ($ref) {

	      $verbose ? printlog ("Skipping posted job $ref->{ValidFrom} $ref->{LocalJobID}. \n") :
		printlog ("Skipping $ref->{LocalJobID}.\n") ;
	      $skipped++ ;
	  } else {
	      unless ($nocommit) {
		  $verbose ?
		      printlog ("Inserting new job: $id, $result->{ownerDN}, $before, $after.$nocommitmsg\n") :
		      printlog ("Inserted: $id.$nocommitmsg\n") ;
		  $insGK->execute($id, $jobid, $jobid, 0, $result->{ownerDN}, 'SiGNET', $before, $after) or die $dbh->errstr;;
		  $insMR->execute($id, $jobid, $jobid, 0, 'SiGNET', $before, $after) or die $dbh->errstr;
	      }
	    $posted++;
	    $startfrom = $dt if $posted and not defined $startfrom ;

	    #handle undo
	    if ($undofile) {
		print $undofile "INSERT INTO GkRecords (GkID, GramScriptJobID, LocalJobID, Processed, GlobalUserName, SiteName, ValidFrom, ValidUntil) VALUES\n";
		print $undofile "INSERT INTO MessageRecords (MsgID, GramScriptJobID, JobName, Processed, SiteName, ValidFrom, ValidUntil) VALUES\n";
	    }
	    }
	  }
	} else {
	printlog ("SKIPPING STRANGE OBJECT:\n$_\n" . Dumper(\$result, \%this_tags) . "\n") ;
      }
      }
      if ($logconf eq 'gm-jobs.log') {
	$prevpos = $lastpos ;
	$lastpos = tell $log;
	$previd = join(' ',
		       $result->{date}, $result->{time},
		       is($result->{lrmsid}), is($result->{ownerDN}) )
      }
    }


    printlog ("\t... done. Report:\n");

    $DB::single = 2;

    $startfrom = DateTime->now() unless defined $startfrom ; #if nothing happened
    $dt = DateTime->now() unless defined $dt ;               #if nothing happened

    printlog ("+ posted $posted, skipped $skipped from " .
	      $startfrom->ymd()  . ' ' . $startfrom->hms() . ' to ',
	      $dt->ymd()  . ' ' . $dt->hms() . "\n");
    printlog ("+ Parser matches: $matches\t Fails: $fails (" .
      sprintf ("%4.2f", ( $fails / ($fails + $matches) * 100)) . " %)\n");
    printlog ("+ Matched patterns:\n");
    foreach (keys %matches) {
      printlog ('+' . sprintf ("%32s:\t%9d (%04.2f %%)\n", $_, $matches{$_}, ($matches{$_} / ($fails + $matches) * 100))) ;
    }
    printlog ("+ Matched tags:\n");
    foreach (keys %tags) {
      printlog ('+' . sprintf ("%32s:\t%9d (%04.2f %%)\n", $_, $tags{$_}, ($tags{$_} / ($fails + $matches) * 100)) ) ;
    }
  }  else  {
    warn "Can't read $conf->{confs}{$logconf}[0]{logfile}, aborting logfile ($!)\n";
    printlog ("Can't read $conf->{confs}{$logconf}[0]{logfile}, aborting logfile ($!)\n");
    next LOG;
  }
}

# commit to db
$dbh->commit() or
  ( printlog( $dbh->errstr() . ", exiting.\n" )
    and die $dbh->errstr() ) ;
$dbh->disconnect() or printlog( $dbh->errstr());

# remember state
close STATE ;
printlog ("No state retained. Exiting.")
  unless (defined $prevpos or defined $rewind or $nocommit) ;
die "No state retained. Exiting.\n" unless (defined $prevpos or defined $rewind  or $nocommit);

open STATE, ">", $statefile
  or die "Can't open state dump file $statefile for writing, @!\n";

$dt = DateTime->now();
print STATE join(' ',
		 $dt->ymd(), $dt->hms(), defined $prevpos ? $prevpos : $rewind,
		 $previd ? '[' . $previd . ']' : ''), "\n";
printlog ("Finished at " .
	  (defined $prevpos ? $prevpos : $rewind ) . ' ' .
	  ($previd ? '[' . $previd . ']' : '') . ".\n") ;


sub printlog {
  return unless defined $logfile;
  my $dt = DateTime->now();
  print $log $dt->ymd() . ' ' . $dt->hms() . ' ', @_ ;
}

sub is {
  return $_[0] ?  $_[0] : '' ;
}


sub usage {
  print <<"FNORD" ;
\u$progname: Incrementaly read new items in NG ARC's gm-jobs log
and post them to the gLite's MySQL data base to be handled
by apel publisher.

\u$progname tries not to repost anything.

The last position read in the log is kept in a statefile between runs.
Grid job entries are fist looked up in the database and only posted if
not yet present.

\u$progname currently parses loggator backend config files,
but does not use them. This will be added soon.

Options:

 --config    -c  Set Loggator configuration directory.
                 See Loggator::Config. Default value: '$config'.
 --logfile   -l  Logfile location for gm-jobs-postmetrics.
                 If empty, no log is kept. Default value: '$logfile'.
 --statefile -s  Statefile where last byte position read and last line
                 is kept between runs. Default: '$statefile'.
                 If empty, no state is preserved.
 --nocommit  -c  Do nothing, just parse the log file and check
                 for duplicates in the database.
 --reparse   -r  Ignore the state file, start from the beginning
                 of the log.
 --verbose   -v  Print info on STDERR while running.
 --debug     -d  Print more info.
 --withundo  -u  Write undo files to specified file.
                 This will append to the file if it exists.
                 A %d and a %t in the filename will be replaced by
                 current date and time in the format of yyyy-mm-dd hh-mm-ss.
 --hostname  -H  Hostname of MySQL server for gLite/apel.
                 If empty, no checking and no posting is performed.
 --port      -p  Port for MySQL server
 --database  -b  MySQL server database.
                 Default: '$database'.
 --username  -U  MySQL remote user.
                 Default: '$user'.
 --password  -P  MySQL password. (Passwords on command line are insecure!)
 --help      -h  Prints this help.

Example:

  $progname -c /etc/$progname/conf.d -H my.host.org -p 3306 -b accounting \
     -U accounting -P password123 \
     -l /var/log/$progname -s /var/state/$progname \
     -u /var/state/$progname-undo-%d-%t 
FNORD
}
