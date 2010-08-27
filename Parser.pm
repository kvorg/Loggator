package Parser;

use strict; use warnings;
use re 'eval';

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
  $self->{res} = [] ;
  $self->{re} = {} ;

  foreach (@{$self->{patterns}})
    {
      my ( $pname ) = keys %{$_};
      push @{$self->{res}}, $pname;  # save pattern order
      $self->{re}{$pname} = join "\n",
	map
	  {
	    my ($a) = keys %$_;
	    $_->{$a} . ($a =~ m/^_/ ? '' : ' (?{ $self->{results}{' . $a . '}=$^N })');
	  } @{$_->{$pname}};
    }
}

sub parse {
  my $self = shift;
  my $line = shift;

  $self->{results} = {} ;
  my $status;

  $status = 1 if (m/$self->{re}{$self->{res}[0]}/x) ; #matches fist pattern:
                                                              #FIX to support many pttrns
  return ($self->{results}, $status);
}

1;
__END__


#! /usr/bin/perl -w  # -*- cperl -*-

# see brenta cgi-bin for panda job links!!

# Atlas olde!
# mc11.005310.PythiaH120gamgam.recon.v11000308._00011.job
# mc11          	name prefix -  setting related
# 005310        	dataset id - user assigned (unique)
# PythiaH120gamgam    	physics short
# recon         	task type (reconstruction)
# v11000308             atlas release 11.0.3 cache 08 (full cache name 11.0.3.8)
# _00011                job # (of the task)
# .job

# Atlas new
# trig1_misal1_csc11.005009.J0_pythia_jetjet.recon.v12000604_tid009670._00752.job
# trig1         	name prefix: tip rekonstrukcije (trigger 1 v tem primeru)
#  _misal1         	name prefix: tip simulacije detektorja (tudi misal0 ipd.)
#  _csc11         	name prefix: event generation -  setting related (csc11 ali mc12, mc11 redko - testno)
# 005310        	dataset id - user assigned (unique)
# PythiaH120gamgam    	physics short
# recon         	task type (reconstruction): recon, evgen, reco, digit
# v12000604             atlas release 11.0.3 cache 08 (full cache name 11.0.3.8)
#  _tid009670            atlas task id (atlas job monitor task id): used also for job resending on Atlas level
# _00011                job # (of the task)
# .job


use strict;
use re 'eval';

#$_ = ' 21-06-2006 10:29:11 Finished - job id: 2613111508408701911166997, unix user: 4102:4100, name: "", owner: "", lrms: , queue: , failure: "Failed reading status of the job."';
#m[(\d{2}-\d{2}-\d{4}) (:? Started | Finished ) \s+ - \s+ job \s id: \s \d+ ,\s+ unix \s user: \s \d+:\d+ , \s+  name: \s "[^"]*" .*]x );

#  m{ #\s+                                        #fails with null/ crash
#     \d{2}-\d{2}-\d{4} \s+                           #date
#     \d{2}:\d{2}:\d{2} \s+                           #time
#     (:? Started | Finished ) \s+ -                  #type
#     \s+ job \s id: \s+ \d+                           #jobid
#     ,\s+ unix \s user: \s+ \d+:\d+                   #unix user
#     , \s+ (:?                                       # (if scheduled)
#            name: \s+ "[^"]*"                         #jobname
#           ,\s+ owner: \s+ "[^"]*"                    #ownerdn
#           ,\s+ lrms: \s+ \w*                         #lrmstype (empty when no staus)
#           (:? ,\s+ queue: \s+ \w* )?                 #queuename
#           (:? ,\s lrmsid: \s+ \d+\.\w+ )?            #lrmsid
#       )?
#     (:? ,\s failure: \s (?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')|(?:\`)(?:[^\\\`]*(?:\\.[^\\\`]*)*)(?:\`)) )?                       #failure (with a RE::Common quoted string pattern)
#     \s+$
#   }x

$_ = ' 21-06-2006 10:29:11 Finished - job id: 2613111508408701911166997, unix user: 4102:4100, name: "", owner: "", lrms: , queue: , failure: "Failed reading status of the job."';
$_= ' 04-02-2006 10:35:03 Started - job id: 1261611390492381360303405, unix user: 4102:4100, name: "mc11.005310.PythiaH120gamgam.recon.v11000308._00011.job", owner: "/O=Grid/O=NorduGrid/OU=fys.uio.no/CN=Alex Read", lrms: pbs, queue: gridlong';
$_ = ' 04-02-2006 10:35:03 Started - job id: 128361139049283226935834, unix user: 4102:4100, name: "mc11.005310.PythiaH120gamgam.recon.v11000308._00013.job", owner: "/O=Grid/O=NorduGrid/OU=fys.uio.no/CN=Alex Read", lrms: pbs, queue: gridlong, lrmsid: 512841.brenta';


my $setup =
  [
   { logfile => '/afs/f9.ijs.si/home/jona/Projects/NG-logmonitor/log.d/var/gm-jobs.log',
     patterns =>
     [
      { standard =>
       [
	{ date =>      '(\d{2}-\d{2}-\d{4}) \s+' },
	{ time =>      '(\d{2}:\d{2}:\d{2}) \s+' },
	{ type =>      '(Started|Finished) \s+ -' },
	{ jobid =>     '\s+ job \s id: \s+ (\d+)'},
	{ unixuser =>  ', \s+ unix \s user: \s+ (\d+:\d+)'},
	{ _jobopen  => '(:? ()' },                          #open
	{ jobname  =>  ', \s+ name: \s+ "([^"]*)"'},
        { ownerDN =>   ',\s+ owner: \s+ "([^"]*)"'},
	{ lrmstype =>  ',\s+ lrms: \s+ ([^,]*)'},
	{ queuename => '(:? , \s+ queue: \s+ ([^,]*) '},
	{ lrmsid =>    ')?(:? ,\s lrmsid: \s+ (\d+\.\w+) '},
	{ _jobclose => ')?() )?'},                          #close
#	{ failure =>   '(:? (:? ,\s+)? ,\s* failure: \s+ ( (?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")) ) ' },
#	{ _close =>  ')? () \s*$'},                          #lineend
	{ failure =>   '(:? (:? (:? ,\s+)? ,\s* failure: \s+ \"(.*)\" \s* $ ' },
	{ _close =>  ')? | (?:\s*$ ) ) () '},                          #lineend

       ],
      },
     ],
   }
  ];


my %logs;

LOG: foreach my $setup (@$setup) {
  if (open my $log, "<", $setup->{logfile})
    {
        $logs{$setup->{logfile}} = { loghandle => $log, #FIXME - while running
				     logfile   => $setup->{logfile},
				     logname   => $setup->{logfile}, #FIXME
				     re        => {},
				     res       => [],
				   };
    }
  else
    {
      warn "Can't read $setup->{logfile}, aborting logfile ($!)\n";
      next LOG;
    }

  foreach (@{$setup->{patterns}})
    {
      my ($pname ) = keys %{$_};
      push @{$logs{$setup->{logfile}}{res}}, $pname;  # save pattern order
      $logs{$setup->{logfile}}{re}{$pname} = join "\n",
	map
	  {
	    my ($a) = keys %$_;
	    $_->{$a} . ($a =~ m/^_/ ? '' : ' (?{ $results{' . $a . '}=$^N })');
	  } @{$_->{$pname}};
    }
}
use YAML;
print Dump($setup, \%logs,);

print "\nProcessing ...";

my $matched = 0;
my $missed = 0;
my @results;

my %results;

foreach my $log (keys %logs) {
  print " $logs{$log}{logname} ";
#  while ( < $logs{$log}{loghandle} > ) {
  while ( <> ) {
    #$DB::single = 2;
#    my %results;
    %results = ();
    if (m/$logs{$log}{re}{$logs{$log}{res}[0]}/x) #FIX to support many pttrns
      {
#	$DB::single = 2;
	print '.';
	$matched++;
	print "\nMatched:\n$_\n"; #  if $results{failure};
#	push @results, { %results };
	print Dump (\%results); # if $results{failure};
      }
    else
      {
	print 'x';
	$missed++;
#	print "\nMissed:\n$_\n";
      }
    #print "Found failure: $results{failure}\n" if (defined $results{failure});
  }
}

print "\n ... done.\n";
print " Missed $missed out of " . ($missed + $matched) . 
  " (" . sprintf ("%4.2f", ( $missed / ($missed + $matched) * 100)) . " %)\n";

print "Results: ", scalar @results, "\n";
foreach (@results) {
  print Dump $_;
}

__END__
my %results= ();

my $re = join "\n", map {
  my ($a) = keys %$_;
  $_->{$a} . ($a =~ m/^_/ ? '' : ' (?{ $results{' . $a . '}=$^N })');
} @pattern;

#debugging
print $re, "\n";

print "\n===\n";

use YAML;
print Dump(\@pattern);

print "\n===\n";


my @results = m/$re/x and print "matched\n";

print (( join "\n", @results), "\n");

print "\n===\n";

while (my @result = each %results)
  {
    print ( (join ":\t", @result), "\n" );
  }
__END__

my $matched = my $fooed = 0;

while (<>) {
 if ( )
   { $matched++; }
 else
   { print "\n\n>>>Foo:\n";  $fooed++; print $_; }
}

print "\n\nMatched: $matched\n Fooed:   $fooed\n";


__DATA__
 24-01-2006 11:57:54 Started - job id: 3132911381038411297929121, unix user: 4102:4100, name: "", owner: "/C=SI/O=SiGNET/O=IJS/OU=F9/CN=Andrej Filipcic/SN=5", lrms: pbs, queue: gridlong
 24-01-2006 11:58:15 Finished - job id: 3132911381038411297929121, unix user: 4102:4100, name: "", owner: "/C=SI/O=SiGNET/O=IJS/OU=F9/CN=Andrej Filipcic/SN=5", lrms: pbs, queue: gridlong, failure: "Job submission to LRMS failed"
 30-01-2006 20:01:58 Started - job id: 30481138651310720108674, unix user: 4102:4100, name: "KitValidation-TEST-11.0.3", owner: "/C=SI/O=SiGNET/O=IJS/OU=F9/CN=Andrej Filipcic/SN=5", lrms: pbs, queue: gridlong
 30-01-2006 20:32:02 Finished - job id: 190571138641504476800716, unix user: 4102:4100, name: "KitValidation-TEST-11.0.3", owner: "/C=SI/O=SiGNET/O=IJS/OU=F9/CN=Andrej Filipcic/SN=5", lrms: pbs, queue: gridlong, lrmsid: 108519.brenta
 04-02-2006 10:35:03 Started - job id: 1261611390492381360303405, unix user: 4102:4100, name: "mc11.005310.PythiaH120gamgam.recon.v11000308._00011.job", owner: "/O=Grid/O=NorduGrid/OU=fys.uio.no/CN=Alex Read", lrms: pbs, queue: gridlong
 04-02-2006 10:35:03 Started - job id: 128361139049283226935834, unix user: 4102:4100, name: "mc11.005310.PythiaH120gamgam.recon.v11000308._00013.job", owner: "/O=Grid/O=NorduGrid/OU=fys.uio.no/CN=Alex Read", lrms: pbs, queue: gridlong, lrmsid: 512841.brenta
 04-02-2006 13:51:05 Started - job id: 2370211390609911429922220, unix user: 4102:4100, name: "mc11.003035.J2_Pt_35_70.digi...skipping..
 05-02-2006 12:06:59 Finished - job id: 2060811391411411019249870, unix user: 4102:4100, name: "mc11.005104.PythiaWenu.recon.v11000305._00178.job", owner: "/O=Grid/O=NorduGrid/OU=fys.uio.no/CN=Alex Read", lrms: pbs, queue: gridlong, failure: "Failed in files download (pre-processing)"
