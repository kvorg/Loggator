# Loggator::Storage::DB
# Actual interface to SQL storage, ie., a backend superclass
# Sub-classed to implement specific storage backends
#  as in Loggator::Storage::DB::SQLite
# Used via Loggator::Storage::Table and Loggator::Storage::View
#
# Subclass and overrule the following:
#  * date arithmetic
#  * column types
#  * schema interaction: table check and create
#  * transaction support
#
# confer specifies storage confs and perl log conf and mappings
# processed and set up by Loggator::Storage
#
# TODO 
# interface for hooks and exports, using views
# raw log string storage (raw or via pointers *(file+line in vi/less format)
# central store for daemon/processor persistant data
#   (last processed items etc.),
#   allowing multiple concurrent invocations (including locking)


use strict; use warnings;

package Loggator::Storage::DB ;

use DBI;
use Loggator::utils qw( testall ) ;

# General methods:

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

  $self->{conf} = shift ; # supposedly hash with
                          #  dsn (data source name), user, password, autocommit
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
  $self->{connected} = 1 if $self->{dbh} ;
  return $self->{dbh};
}

sub connected {
    return shift()->{connected};
}

sub schema_ensure {
  my $self = shift;
  my $table = shift;
  $self->schema_create($table)
    unless $self->schema_validate($table);
}

sub schema_validate {
  my $self = shift;
  my $table = shift;
  my $tablename = $table->name();
  my $types = $table->types();
  $self->dbconnect() unless $self->connected();

  # check that all columns are present
  testall {
      $self->{dbh}->do(<<"FNORD");
SELECT *
 FROM information_schema.columns
 WHERE table_schema = XXX
 AND table_name '$tablename'
 AND column_name = $_
 AND column_type = $types->{$_}
FNORD
  } (@{$table->columns()})
}

sub schema_create {
  my $self = shift;
  my $table = shift;
  my $tablename = $table->name();
  my $tbl_types = $table->types();
  my %schema_types;

  foreach my $clmn (keys %$tbl_types) {
    $schema_types{$clmn} = $self->convert_type( $tbl_types->{$clmn} ) ;
  }

  $self->dbconnect() unless $self->connected();

  $self->{dbh}->do("CREATE TABLE $tablename ( id " .
		   $self->primarykey_type() . ', ' .
		   join( ', ',
			 map { "$_ " . $schema_types{$_}  } @{$table->columns()}
			 )
		   . ');') ;
}


sub insert {
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

sub select {
}

sub update {
}

sub delete {
}

# Things to subclass and adapt:

sub convert_type { # takes a source type and return suitable target type
  die "Type conversion should be supplied by DB-specific implementation!\n";
}

sub primarykey_type { # return suitable primary key SQL incantation
  die "Primary key specification should be supplied by DB-specific implementation!\n";
}

sub convert_date {
  die "Date conversion should be supplied by DB-specific implementation!\n";
}

sub transaction_start {
  die "Transaction support be supplied by DB-specific implementation!\n";
}

sub transaction_end {
  die "Transaction support be supplied by DB-specific implementation!\n";
}

sub rollback {
  die "Transaction support be supplied by DB-specific implementation!\n";
}



__END__
### Implementation details: ###

difference for stores and exports:
 for stores, we have to create tables if not existing
 for exports, we expect tables to exist and fail if they don't
 (assuming we don' own export tables)

i.e. prd DBD
$dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
possibly additional flags:
 DBI:mysql:database=$database;host=$hostname;port=$port;mysql_server_prepare=1

@databases = DBI->data_sources("mysql");
  or
@databases = DBI->data_sources("mysql",
            {"host" => $host, "port" => $port, "user" => $user, password => $pass});

SQLite case:
my $dbh = DBI->connect("dbi:SQLite:dbname=dbfile","","");

column names in result: my $names = $sth->{'NAME'} (ref to array)
                        my $numFields = $sth->{'NUM_OF_FIELDS'};
                        my $colTypes = $sth->{'TYPE'};

create table, drop table support
error checking

use prepare for storage if possible (DBD:Pg)

Taming date-time: (hmm, missing SQLlite)

  use DBI;
  use DateTime;
  use DateTime::Format::DBI;

  my $db = DBI->connect('dbi:...');
  my $db_parser = DateTime::Format::DBI->new($dbh);
  my $dt = DateTime->now();

  $db->do("UPDATE table SET dt=? WHERE foo='bar'",undef,
    $db_parser->format_datetime($dt);

parse_datetime( $string ) format_datetime( $string ) 
parse_duration( $string ) format_duration( $string ) 

SQLite: http://www.perl.com/lpt/a/770

i.e.:
CREATE TABLE events (id INTEGER PRIMARY KEY, session INTEGER, date TEXT, name TEXT);
CREATE TABLE tagnames (id INTEGER PRIMARY KEY, tagname TEXT);
CREATE TABLE tags (id INTEGER PRIMARY KEY, tagname_id INTEGER, event_id INTEGER);
CREATE TABLE tagvaluenames (id INTEGER PRIMARY KEY, tagvaluename TEXT);
CREATE TABLE tagvalues_ints (id INTEGER PRIMARY KEY, tag_id INTEGER, value INTEGER);
CREATE TABLE tagvalues_text (id INTEGER PRIMARY KEY, tag_id INTEGER, value TEXT);

INSERT INTO "events" VALUES(NULL,7,'2007-10-09 07:36:34','Happy start.');
INSERT INTO "events" VALUES(NULL,7,'2007-10-09 07:37:01','Happy end.');

INSERT INTO "tagnames" VALUES(NULL,'start');
INSERT INTO "tagnames" VALUES(NULL,'stop');
INSERT INTO "tagnames" VALUES(NULL,'success');
INSERT INTO "tagnames" VALUES(NULL,'failure');

INSERT INTO "tags" VALUES(NULL,(SELECT id FROM tagnames WHERE tagname = 'start'),1);
INSERT INTO "tags" VALUES(NULL,(SELECT id FROM tagnames WHERE tagname = 'stop'),2);
INSERT INTO "tags" VALUES(NULL,(SELECT id FROM tagnames WHERE tagname = 'failure'),2);

INSERT INTO tagvalues_ints VALUES (NULL, 3, 404);
INSERT INTO tagvalues_text VALUES (NULL, 2, 'files:erroneous.null');

SELECT events.id, events.date, events.name, tagnames.tagname AS type, tagvalues_ints.value
 FROM events, tags, tagnames, tagvalues_ints
 WHERE events.id = event_id
  AND tagname_id = tagnames.id
  AND type = 'failure'
  AND tags.id = tagvalues_ints.tag_id; 

SELECT events.id, events.date, events.name, tagnames.tagname AS type, tagvalues_text.value
 FROM events, tags, tagnames, tagvalues_text
 WHERE events.id = event_id
  AND tagname_id = tagnames.id
  AND tags.id = tagvalues_text.tag_id;

# or, ANSI SQL:
SELECT events.id, events.date, events.name, tagnames.tagname AS type, tagvalues_text.value
 FROM events JOIN tags, tagnames, tagvalues_text
 ON events.id = event_id
  AND tagname_id = tagnames.id
  AND tags.id = tagvalues_text.tag_id;
