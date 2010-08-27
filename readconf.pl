#! /usr/bin/perl
use Confer ;
use Data::Dumper;

my $conf = Confer->new('log.d');
$conf->process();

print Dumper $conf;
