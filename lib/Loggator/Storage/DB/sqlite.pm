# Loggator::Storage::DB::sqlite
# implementation of sqlite driver-specific details for Loggator::Storate::DB

use strict; use warnings;

package Loggator::Storage::DB::sqlite ;

use DBI;
use Loggator::utils qw( testall ) ;

use base 'Loggator::Storage::DB';

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

sub convert_type { # takes a source type and return suitable target type
  die "Type conversion should be supplied by DB-specific implementation!\n";
}

our $sqlite_types = {
}

sub primarykey_type { # return suitable primary key SQL incantation
    return '';
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
