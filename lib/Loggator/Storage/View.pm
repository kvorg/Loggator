# implement read-only views
# queries can be exported to a new table
# providing export implementation
# (Define view-building syntax!)

use strict; use warnings;

use Loggator::Storage::Table;

package Loggator::Storage::View ;
use base 'Loggator::Storage::Table';


1;
