package Loggator::DB::Main::Data_Date;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('data_date');
__PACKAGE__->add_columns(qw/ data_dateid data logentry value /);
__PACKAGE__->set_primary_key('data_dateid');
__PACKAGE__->belongs_to( 'logentry' => 'Loggator::DB::Main::LogEntry' );
__PACKAGE__->belongs_to( 'data' => 'Loggator::DB::Main::Data' );
