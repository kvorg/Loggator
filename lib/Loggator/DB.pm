#! /usr/bin/perl
# change datatypeid in data types to datakind id
package Loggator::DB;
use warnings; use strict;

use DBI;
use Loggator::DB::Main;
use Carp;

=head1 SYNOPSIS

    my $db = Loggator::DB ->new();
    $db->init( { dsn => '...', user => '...' password => '...');
    #or    my $db = Loggator::DB ->new( { dsn => '...', 
    #                                      user => '...' password => '...');

    db->register_log( log => 'logname', path => '...', logentries => 
                       { name => 'logentryname', data =>
                           [
                                { name => 'original_name', mapping => 'db_name'    kind => 'value', type => 'string' }, 
                                ...
                           ]
                       } 
                );

   db->insert('logentry', 'timestamp', [ 
     { name => 'user',    kind => 'value', value => '...' },
     ...
     ]);

  db->search_log( 'log', 'logentryname', { <dbx search terms> } ) ;

  #more oo opiton - perhaps not needed
  my $log = db->register_log(..);
  $log->insert('logentryname', [...]);

  #STEP TWO!!

  db->register_object( <here_be_dragons> ) ;
  # possibly just join statements with asses 
  # would have to have relevant pivot tables ready !!!

  db->search( 'objectname', { <dbx compound-object search terms> } ) ;

  # or provide object methods: $log->search() $object->serach

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  $self->_init(@_) if scalar @_;

  return $self;
}

sub _init {
  my $self = shift;
  $self->{conf} = shift ;

  carp "DB object should be initialised with a Confer::Backend, such as\n" .
      "obtained from \$confer->Backends, not a " . ref $self->{conf} . "!\n"
      and return unless ref $self->{conf}->isa( 'Confer::Backend' );

  $self->{db} = $self->{confer}->dbi();
  $self->{user} = $self->{confer}->user();
  $self->{password} = $self->{confer}->password();
  $self->{options} = $self->{confer}->options();
  $self->{hostinfo} = $self->{confer}->host() . ':' . $self->{confer}->port() ;
  $self->{filename} = $self->{confer}->filename() if  $self->{confer}->filename();
  $self->{datatypes} = map { { $_ => 1 } } #known datatypes in schema
    qw( bool int float timestamp date duration string text );
  $self->{datatables} = map { { $_ => 1 } } #existing data tables
    qw( data_bool data_int data_float data_timestamp data_date data_duration data_string data_text );
  $self->{datakinds} = map { { $_ => 1 } } #known datatypes in schema
    qw( value flag );
  $self->{schema} = undef;

  use Data::Dumper;
  warn Dumper ($self);
}

sub connect {
  my $self = shift;
  $self->{schema} = Loggator::DB::Main->connect($self->{db})
    unless defined $self->{schema}
}

sub register_logs {
    my $self = shift ;
    my @logs = @_;
    $self->connect();

    foreach my $log (@logs) {
      my $specs = $log->specs() ;

      #cosistency (should also be assured by DB)
      warn "Unknown data type $specs->{type}, skipping definition from log $specs->{log}'\n" and next
	unless defined  $self->{datatypes}{$specs->{type}} ;
      warn "Unknown data kind $specs->{kind}, skipping definition from log $specs->{log}'\n" and next
	unless defined  $self->{datakinds}{$specs->{kind}} ;

      #assure the log data in db
      $self->{schema}->resultset('Log')->find_or_create(
							name => $specs->{log},
							file => $specs->{logfile},
						       );
      #assure the data perl log inforation in db
      $self->{schema}->resultset('Data')->find_or_create(
							 name => $specs->{name},
							 datatype => $specs->{type},
							 kind => $specs->{kind},
							 log => $specs->{log},
							);
    }
  }

sub insert {
  my $self = shift;
  my $logname = shift;
  my $timestamp = shift;
  my $data = shift; # [{ name => 'user', kind => 'value', value => '...' }, ]

  $self->connect();

  my $log  = $self->{schema}->resultset('Log')->find({ name => $logname })->id;

  my ($logentry) = $self->{schema}->populate('LogEntry', [
							  [qw(log timestamp)],
							  [  $log, $timestamp ]
							 ] );

  foreach ( @$data ) {
    warn "No value of type $_->{name} exists in the database, skipping.\n"
      and next
	unless $self->{schema}->resultset('Data')->find({  name => $_->{name} })->datatype;
    warn " type $_->{name} kind $_->{kind}\n";
    #$DB::single = 2;
    my $data = $self->{schema}->resultset('Data')->find({ name => $_->{name}, log => $log})->id;
    my $type = $self->{schema}->resultset('Data')->find({ name => $_->{name}, log => $log })->datatype->type;
    my $kind = $self->{schema}->resultset('Data')->find({ name => $_->{name}, log => $log })->datakind->kind;
    warn "Inserting $_->{name}: $_->{value} as $type ($kind) for logentry " . $logentry->id ."\n";
    $self->{schema}->populate("Data_\u$type" , [
						[qw(data value logentry)],
						[ $data, $_->{value}, $logentry->id ]
					       ] );
  }
}


sub init_db {
    my $self = shift ;
    die "Only know how to handle SQLite at this time, sorry.\n"
      unless $self->{db} =~ /sqlite/i ;
    warn "Unlinking db.\n";
    unlink $self->{filename};
    warn "Connecting to db.\n";
    my $dbh = DBI->connect($self->{db},"","") and warn "Connected.\n";

$dbh->do(<<FNORD);
  CREATE TABLE logentry (
    logentryid INTEGER PRIMARY KEY,
    log INTEGER NOT NULL REFERENCES log(logid),
    timestamp DATE NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE log (
    logid INTEGER PRIMARY KEY,
    name VARCHAR(32) NOT NULL,
    file VARCHAR(256) NOT NULL
  );
FNORD
$dbh->do(<<FNORD); # value or tag
  CREATE TABLE datakind (
    datakindid INTEGER PRIMARY KEY,
    kind VARCHAR(16) NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE datatype (
    datatypeid INTEGER PRIMARY KEY,
    type VARCHAR(16) NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data (
    dataid INTEGER PRIMARY KEY,
    name  VARCHAR(16),
    datatype INTEGER NOT NULL REFERENCES datatype(datatypeid),
    datakind INTEGER NOT NULL REFERENCES datakind(datakindid),
    log INTEGER NOT NULL REFERENCES log(logid),
    UNIQUE (name, log, datakind)
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_bool (
    data_boolid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value INT NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_int (
    data_intid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value INT NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_float (
    data_floatid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value FLOAT NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_timestamp (
    data_timestampid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value DATE NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_date (
    data_dateid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value DATE NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_duration (
    data_durationid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value INTEGER NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_string (
    data_stringid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value VARCHAR(255) NOT NULL
  );
FNORD
$dbh->do(<<FNORD);
  CREATE TABLE data_text (
    data_textid INTEGER PRIMARY KEY,
    data NOT NULL REFERENCES data(dataid),
    logentry INTEGER NOT NULL REFERENCES logenry(logentryid),
    value TEXT NOT NULL
  );
FNORD

    my @datakinds = ( ['value'], ['tag'] );
    $self->connect();
    $self->{schema}->populate('DataKind', [ [qw(kind)], @datakinds ] );
    warn "DataKind populated.\n";
  }


__END__
my $db = "dbi:SQLite:dbname=testdbix.sqlite";
init_db ($db);
my $schema = Loggator::DB::Main->connect($db);


my @logs = ( ['log1', '/path/to/log1'], ['log2', '/path/to/log2'] );

my @data = 
  (
   { name => 'user',    kind => 'value', type => 'string',    log => 'log1' },
   { name => 'time',    kind => 'value', type => 'timestamp', log => 'log1' },
   { name => 'file',    kind => 'value', type => 'text',      log => 'log1' },
   { name => 'failure', kind => 'tag',   type => 'bool',      log => 'log1' },
   { name => 'file',    kind => 'value', type => 'text',      log => 'log2' },
   { name => 'failure', kind => 'tag',   type => 'bool',      log => 'log2' },
  );

my @entries = (
	       { log => 'log1', timestamp=> 33,
		 values => [ {name => 'user', kind => 'value', value => 'pepe' }, {name => 'file', kind => 'value', value => '/home/users/pepe' }, {name => 'failure', kind => 'tag',  value => 1 }, ] },
	       { log => 'log1', timestamp=> 66,
		 values => [ {name => 'time',kind => 'value',  value => 666 }, ] },
	       { log => 'log1', timestamp=> 88,
		 values => [ {name => 'file', kind => 'value', value => '/path/to/pepe' }, ] },
	       { log => 'log2', timestamp=> 99,
		 values => [ {name => 'file', kind => 'value', value => '/path/to/dolfe' }, ] },
	       { log => 'log2', timestamp=> 666,
		 values => [ {name => 'failure', kind => 'tag',  value => 1 }, ] },
	      );

warn "Populating db.\n";

$schema->populate('Log', [ [qw(name file)], @logs ] );

warn "Log populated.\n";

$schema->populate('DataType', [ [qw(type)],
				map { [$_] }
				unique (map { $_->{type} }
						    @data) ] );

warn "DataType populated.\n";


my @datastruct ;
foreach (@data) {
  my $type = $schema->resultset('DataType')->find({ type => $_->{type} })->id ;
  my $kind = $schema->resultset('DataKind')->find({ kind => $_->{kind} })->id;
  my $log  = $schema->resultset('Log')->find({ name => $_->{log} })->id;
  my $name =  $_->{name} ;

  #$DB::single=2;

  #print "Type: $_->{type}/" . $type->first->datatypeid . "\nLog: $_->{log}/" . $log->first->logid . "\nName:$_->{name}\n";
  push @datastruct, [  $name, $type, $kind, $log ] ;
}

$schema->populate('Data', [
			   [qw(name datatype datakind log)],
			   @datastruct
			  ] );

warn "Data populated.\n";

@datastruct = ();
my @values ;
foreach (@entries) {
  my $log  = $schema->resultset('Log')->find({ name => $_->{log} })->id;

  my ($logentry) = $schema->populate('LogEntry', [
			   [qw(log timestamp)],
			   [  $log, $_->{timestamp} ]
			  ] );
  foreach ( @{$_->{values}} ) {
    warn "No value of type $_->{name} exists in the database, skipping.\n"
      and next
	unless $schema->resultset('Data')->find({  name => $_->{name} })->datatype;
    warn "No value of kind $_->{kind} exists in the database, skipping.\n"
      and next
	unless 1; #add check here
    warn " type $_->{name} kind $_->{kind}\n"; my $desc= "$_->{name} kind $_->{kind}";
    #$DB::single = 2;
    my $data = $schema->resultset('Data')->find({ name => $_->{name}, log => $log})->id;
    my $type = $schema->resultset('Data')->find({ name => $_->{name}, log => $log })->datatype->type;
    my $kind = $schema->resultset('Data')->find({ name => $_->{name}, log => $log })->datakind->kind;
    warn "Inserting $_->{name}: $_->{value} as $type ($kind) for logentry " . $logentry->id ."\n";
    $schema->populate("Data_\u$type" , [
						[qw(data value logentry)],
						[ $data, $_->{value}, $logentry->id ]
					       ] );

  }


}

warn "LogEntries populated.\n";



####### tips & tricks
#my $x = $schema->resultset('LogEntry')->find({ log => 1})->search_related('data_bools', { Value => 'pepe'});
#$x = $schema->resultset('LogEntry')->search_related('data_bools', { Value => 'pepe'});
#$schema->resultset('LogEntry')->first->find_related('data_bools',  { Value => 'pepe'}); 
#$schema->resultset('LogEntry')->find({ log => 1})->add_to_data_bools({ value => 2, datakindid => $schema->resultset('DataKind')->find({ kind => 'tag' })->id });
#$schema->resultset('LogEntry')->find({ log => 1})->count_related('data_bools');
# tudi: find_or_create_related update_or_create_related
# update_from_related delete_related
# $schema->resultset('User')->create( \%user_data );
#######


my $rs = $schema->resultset('Log')->search( { 'name' => 'log1' }, );
print $rs->first->name, " ", $rs->first->file, "\n";

my @datatables = qw( data_bool data_int data_float data_timestamp data_date data_duration data_string data_text );

my $entries = $schema->resultset('LogEntry')->search({'log.name' =>  'log1' }, { join => ['log'], prefetch => ['log'] });

while (my $entry = $entries->next() ) {
  print 'log1: ' . $entry->timestamp . "\n";
  my (@values, @tags);
  foreach (@datatables) {
#  $DB::single = 2;
#    push @values, $entry->search_related($_ . 's');
    push @values,
      $entry->search_related($_ . 's',
			     {'data.datakind' =>
			      $schema->resultset('DataKind')->find({ kind => 'value' })->id },
			     { join => [ 'data' ], prefetch => [ 'data' ] }
			    ) ;
    push @tags,
      $entry->search_related($_ . 's',
			     {'data.datakind' =>
			      $schema->resultset('DataKind')->find({ kind => 'tag' })->id },
			     { join => [ 'data' ],  prefetch => [ 'data' ] }
			    ) ;
  }
  print ' Values: ', join (', ', map { $_->data->name . ': ' . $_->value } @values);
  print "\n";
  print ' Tags: ' , join (', ', map { $_->data->name . ': ' . $_->value } @tags);
  print "\n";
}


#utility
sub unique {
  my %seen = ();
  $seen{$_} = 1 foreach @_;
  return keys %seen;
}


#init dbase (consider better types for other sql backends
