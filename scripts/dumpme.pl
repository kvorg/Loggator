#! /usr/bin/perl

use YAML qw( Dump );
use Data::Dumper;

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


print Dumper $data;
print Dump $data;


