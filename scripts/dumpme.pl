#! /usr/bin/perl

use YAML qw( Dump );
use Data::Dumper;

use warnings;

$data =
    [ 
      { logfile => 'name',
	patterns => [ 
	    { 
		name1 => { re => [ { rename1 => 'pttrn' },
				   { rename2 => 'pttrn' } 
			       ],
			   tags => { tagname => 'pttrn' }
		}
	    },
	    {	
		name2 => { re => [ { rename => 'pttrn' } ] }
	    }
	    ]
      }
    ] ;

$data = { 'SQLite-local' => { db => 'DBI::SQLite', args => { xx => 1, yy => 2 } } };

print Dumper $data;
print Dump $data;


