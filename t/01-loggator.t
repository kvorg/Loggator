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

BEGIN {
  use_ok 'Loggator::Parser';
  use_ok 'Loggator::Confer';
}

my $config = 'test.rc' ;
# check for readabilty of dir and contents

my $c = Loggator::Confer->new($config);
# test the structure

#extract logs

my $p = Loggator::Parser->new( $conf->{confs}{$logconf}[0]{patterns} );

