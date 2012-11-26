package Loggator::DB::Main::Data_Duration;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data_duration');
__PACKAGE__->add_columns(qw/ data_durationid data logentry value /);
__PACKAGE__->set_primary_key('data_durationid');
__PACKAGE__->belongs_to( 'logentry' => 'Loggator::DB::Main::LogEntry' );
__PACKAGE__->belongs_to( 'data' => 'Loggator::DB::Main::Data' );
