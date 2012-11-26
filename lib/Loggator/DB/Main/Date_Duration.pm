package Loggator::DB::Main::Data_Duration;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data_duration');
__PACKAGE__->add_columns(qw/ dataid logentryid value /);
__PACKAGE__->set_primary_key('dataid');
__PACKAGE__->belongs_to( 'logentry' => 'Loggator::DB::Main::LogEntry' );
