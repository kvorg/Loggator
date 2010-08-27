package Loggator::DB::Main::Data_Date;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data_date');
__PACKAGE__->add_columns(qw/ dataid logentryid value /);
__PACKAGE__->set_primary_key('dataid');
__PACKAGE__->belongs_to( 'logentry' => 'Loggator::DB::Main::LogEntry' );
