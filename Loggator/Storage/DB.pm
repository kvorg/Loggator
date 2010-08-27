# Interface so SQL storage
# confer should be used to specify storage
# extend log configurations to specify mappings and storage confs to use
# (or use separate conffiles for mappings and stores / probably not)
# add intefrace to use retrived data in hooks and exports
# option to store raw log strings or at least pointers *(file+line in vi/less format)
# difference for stores and exports:
#  for stores, we have to create tables if not existing
#  for exports, we expect tables to exist and fail if they don't
#  (assuming we don' own export tables)
#  implemnet a store for our persistant data (last processed items etc.),
#  allowing for multiple daemons to coexist

# i.e. prd DBD
# $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
# possibly additional flags:
#  DBI:mysql:database=$database;host=$hostname;port=$port;mysql_server_prepare=1
#
# @databases = DBI->data_sources("mysql");
#   or
# @databases = DBI->data_sources("mysql",
#             {"host" => $host, "port" => $port, "user" => $user, password => $pass});

# SQLite case:
# my $dbh = DBI->connect("dbi:SQLite:dbname=dbfile","","");

# column names in result: my $names = $sth->{'NAME'} (ref to array)
#                         my $numFields = $sth->{'NUM_OF_FIELDS'};
#                         my $colTypes = $sth->{'TYPE'};

# create table, drop table support
# error checking

# use prepare for storage if possible (DBD:Pg)

# Taming date-time: (hmm, missing SQLlite)
#
#   use DBI;
#   use DateTime;
#   use DateTime::Format::DBI;
#
#   my $db = DBI->connect('dbi:...');
#   my $db_parser = DateTime::Format::DBI->new($dbh);
#   my $dt = DateTime->now();
#
#   $db->do("UPDATE table SET dt=? WHERE foo='bar'",undef,
#     $db_parser->format_datetime($dt);
#
# parse_datetime( $string ) format_datetime( $string ) 
# parse_duration( $string ) format_duration( $string ) 

# SQLite: http://www.perl.com/lpt/a/770

package DB ;

use DBI;

use strict; use warnings;

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

  $self->{conf} = shift ; # supposedly dsn (data source name), user, password, autocommit
  $self->{map} = shift ;  # mappings

  $self->{dbh} = undef;
  $self->{sth} = undef;
  $self->{connected} = undef;
}

sub DESTROY {
  my $self = shift;
  return $self->{dbh}->disconnect() if ($self->{connected} or $self->{dbh});
}

sub dbconnect {
  my $self = shift;

  $self->{dbh} = DBI->connect(
			      $self->{conf}{dsn},
			      ( defined $self->{conf}{user} 
				&& defined $self->{conf}{password} ?
				($self->{conf}{user}, $self->{conf}{password}) :
				()
			      ),
			      {
			       RaiseError => $self->{conf}{raiseerror},
			       AutoCommit => $self->{conf}{autocommit},
			      }
			     )
    unless (defined $self->{dbh} and $self->{connected});
  return $self->{dbh};
}


sub store {
  my $self  = shift;
  my $table = shift; #hmmm - how to deduce table mappings?
  my @what = @_; # data records as references

  my $dbh = $self->{dbh};
  my $sth = $self->{sth};

  $self->dbconnect() unless (defined $dbh and $self->{connected});

  foreach my $record (@what) {
    # FIX: apply redirections
    # FIX: apply transformations (dates, numbers) - dbd depending object iface
    #      with roolback and error on failure
    # use $dbh->quote() for quoting

    $sth = $dbh->prepare( "INSERT INTO table(foo,bar,baz) VALUES (?,?,?)" );
#    $sth->execute( $values, $values, $values );
  }
  # FIX: do we have to store dbh back (references, hmm)
  # FIX: autocommit thingies
  return $dbh->commit;
}

sub retrieve {
  # apply redirections
  # build select
  # apply transformations (dates, numbers) - dbd depending object iface
  # return reference to array of results

  my $self = shift;

  my $dbh = $self->{dbh};
  my $sth = $self->{sth};

  $self->dbconnect() unless (defined $dbh and $self->{connected});

}

sub translate_date {
  #wrapper to call the suitable solution for the underlying implementation
}
