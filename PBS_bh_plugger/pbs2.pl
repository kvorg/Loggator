#!/usr/bin/perl
use strict;
use Data::Dumper;

my $afile=shift || "/var/spool/PBS/server_priv/accounting/".getdate();

my $acc;
my $limit=10;

open FI,"<$afile";
while(<FI>) {
    if($_=~/([^\;]+)\;([^\;]+)\;([^\;]+)\;(.+)/) {
	if($2 eq 'E') {
	    my $str=$4;
	    my $host=kmatch("exec_host",$str);
	    $host=~s/\/\d+//;
	    $acc->{$host}->{Exit_status}->{kmatch("Exit_status",$str)}++;
	}
    }
}

close FI;

print $_, Dumper($acc);

foreach my $key (keys %$acc) {
    my $h=$acc->{$key}->{Exit_status};
    foreach my $k (keys %$h) {
	#print "$k ".$h->{$k}."\n";
	if( ($k ne 0) && $h->{$k} > $limit ) {
	    print "$key $k ".$h->{$k}."\n";
	}
    }
}

sub kmatch {
    my $key=shift;
    my $str=shift;
    if ($str=~/$key=([^\s]+)/) {
	return $1;
    } else {
	return "";
    }
}

sub getdate {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $mon++;
    $year+=1900;
    $mon="0$mon" if $mon<10;
    return "$year$mon$mday";
}
