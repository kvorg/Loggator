#! /usr/bin/perl
use Loggator::Confer ;
use Data::Dumper;

my $conf = Loggator::Confer->new('log.d');
$conf->process();

print Dumper $conf;
