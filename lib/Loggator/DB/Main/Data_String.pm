package Loggator::DB::Main::Data_String;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data_string');
__PACKAGE__->add_columns(qw/ data_stringid data logentry value /);
__PACKAGE__->set_primary_key('data_stringid');
__PACKAGE__->belongs_to( 'logentry' => 'Loggator::DB::Main::LogEntry' );
__PACKAGE__->belongs_to( 'data' => 'Loggator::DB::Main::Data' );
