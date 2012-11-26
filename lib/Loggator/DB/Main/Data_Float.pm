package Loggator::DB::Main::Data_Float;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data_float');
__PACKAGE__->add_columns(qw/ data_floatid data logentry value /);
__PACKAGE__->set_primary_key('data_floatid');
__PACKAGE__->belongs_to( 'logentry' => 'Loggator::DB::Main::LogEntry' );
__PACKAGE__->belongs_to( 'data' => 'Loggator::DB::Main::Data' );
