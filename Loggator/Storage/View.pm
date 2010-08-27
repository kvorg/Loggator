# implement read-only views
# queries can be exported to a new table
# providing export implementation
# (Define view-building syntax!)

package Storage::View ;

use Storage::DB;
use Storage::Table;

use strict; use warnings;

use base 'Storage::Table';


1;
