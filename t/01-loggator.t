#!/usr/bin/env perl
use strict; use warnings;
use lib qw(lib ../ ../lib );

use Test::More; # tests => 1;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Data::Dumper;
$Data::Dumper::Indent = 2;

# external dependencies
BEGIN {
  use_ok 'DateTime'
    or die "\nFAIL: Package DateTime is a prerequisite, sorry. Please install using 'cpan' or your package tool.\n\n";
  use_ok 'YAML'
    or die "\nFAIL: Package YAML is a prerequisite, sorry. Please install using 'cpan' or your package tool.\n\n";
  use_ok 'DBI'
    or die "\nFAIL: Package DBI is a prerequisite, sorry. Please install using 'cpan' or your package tool.\n\n";
}
# base packages dependencies
BEGIN {
  use_ok 'Loggator::Parser';
  use_ok 'Loggator::Confer';
}

my $config = 't/test.rc' ;
# check for readabilty of dir and contents
ok ((-r -d $config), "Availability of test dir $config");

my $c = Loggator::Confer->new('pepe');

$c = Loggator::Confer->new($config);
# test the structure

#extract logs
my $logconf = 'missing';
my $p = Loggator::Parser->new( $c->{confs}{$logconf}[0]{patterns} );

done_testing;

